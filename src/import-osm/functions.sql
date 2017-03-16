-----------------------------------
--                               --
--  FUNCTIONS FOR IMPORTING DATA --
--                               --
-----------------------------------

CREATE OR REPLACE FUNCTION rank_place(type TEXT, osmID bigint)
RETURNS int AS $$
BEGIN
	RETURN CASE
		WHEN type IN ('administrative') THEN 2*(SELECT COALESCE(admin_level,15) FROM osm_polygon_tmp o WHERE osm_id = osmID)
		WHEN type IN ('continent', 'sea') THEN 2
		WHEN type IN ('country') THEN 4
		WHEN type IN ('state') THEN 8
		WHEN type IN ('county') THEN 12
		WHEN type IN ('city') THEN 16
		WHEN type IN ('island') THEN 17
		WHEN type IN ('region') THEN 18 -- dropped from previous value of 10
		WHEN type IN ('town') THEN 18
		WHEN type IN ('village','hamlet','municipality','district','unincorporated_area','borough') THEN 19
		WHEN type IN ('suburb','croft','subdivision','isolated_dwelling','farm','locality','islet','mountain_pass') THEN 20
		WHEN type IN ('neighbourhood', 'residential') THEN 22
		WHEN type IN ('houses') THEN 28
		WHEN type IN ('house','building') THEN 30
		WHEN type IN ('quarter') THEN 30
	END;
END;
$$ LANGUAGE plpgsql IMMUTABLE;


CREATE OR REPLACE FUNCTION rank_address(type TEXT)
RETURNS int AS $$
BEGIN
	RETURN CASE
		WHEN type IN ('service','cycleway','path','footway','steps','bridleway','motorway_link','primary_link','trunk_link','secondary_link','tertiary_link') THEN 27
		ELSE 26
	END;
END;
$$ LANGUAGE plpgsql IMMUTABLE;


CREATE OR REPLACE FUNCTION determineCountryCodeAndPartition()
RETURNS TRIGGER AS $$
DECLARE
  place_centroid GEOMETRY;
BEGIN

  	place_centroid := ST_PointOnSurface(NEW.geometry);

    -- recalculate country and partition
    IF NEW.rank_search = 4 THEN
      -- for countries, believe the mapped country code,
      -- so that we remain in the right partition if the boundaries
      -- suddenly expand.
      NEW.partition := get_partition(lower(NEW.country_code));
      IF NEW.partition = 0 THEN
        NEW.calculated_country_code := lower(get_country_code(place_centroid));
        NEW.partition := get_partition(NEW.calculated_country_code);
      ELSE
        NEW.calculated_country_code := lower(NEW.country_code);
      END IF;
    ELSE
      IF NEW.rank_search > 4 THEN
        NEW.calculated_country_code := lower(get_country_code(place_centroid));
      	NEW.partition := get_partition(NEW.calculated_country_code);
      END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION determineParentPlace(id_value BIGINT, partition_value INT, rank_search_value INT, geometry_value GEOMETRY) RETURNS BIGINT AS $$
DECLARE
  retVal BIGINT;
BEGIN
  FOR current_rank  IN REVERSE rank_search_value..1 LOOP
     SELECT id FROM osm_polygon WHERE partition=partition_value AND rank_search = current_rank AND NOT id=id_value AND ST_Contains(geometry, geometry_value) AND NOT ST_Equals(geometry, geometry_value) INTO retVal;
     IF retVal IS NOT NULL THEN
      return retVal;
    END IF;
  END LOOP;
RETURN retVal;
END;
$$ LANGUAGE plpgsql;

DROP FUNCTION IF EXISTS findRoadsWithinGeometry(BIGINT,INT,geometry);
CREATE OR REPLACE FUNCTION findRoadsWithinGeometry(id_value BIGINT,partition_value INT, geometry_value GEOMETRY) RETURNS VOID AS $$
BEGIN
	UPDATE osm_linestring SET parent_id = id_value WHERE parent_id IS NULL AND ST_Contains(geometry_value,geometry);
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION determineRoadHierarchyForEachCountry() RETURNS void AS $$
DECLARE
  retVal BIGINT;
BEGIN
  FOR current_partition  IN 1..255 LOOP
    FOR current_rank  IN REVERSE 22..4 LOOP
       PERFORM findRoadsWithinGeometry(id, current_partition, geometry) FROM osm_polygon WHERE partition = current_partition AND rank_search = current_rank;
    END LOOP;
  END LOOP;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION get_country_language_code(search_country_code VARCHAR(2)) RETURNS TEXT
  AS $$
DECLARE
  nearcountry RECORD;
BEGIN
  FOR nearcountry IN select distinct country_default_language_code from country_name where country_code = search_country_code limit 1
  LOOP
    RETURN lower(nearcountry.country_default_language_code);
  END LOOP;
  RETURN NULL;
END;
$$
LANGUAGE plpgsql IMMUTABLE;


CREATE OR REPLACE FUNCTION get_country_code(place geometry) RETURNS TEXT
  AS $$
DECLARE
  place_centre GEOMETRY;
  nearcountry RECORD;
BEGIN
  place_centre := ST_PointOnSurface(place);

  FOR nearcountry IN select country_code from country_osm_grid where st_covers(geometry, place_centre) order by area asc limit 1
  LOOP
    RETURN nearcountry.country_code;
  END LOOP;

  FOR nearcountry IN select country_code from country_osm_grid where st_dwithin(geometry, place_centre, 0.5) order by st_distance(geometry, place_centre) asc, area asc limit 1
  LOOP
    RETURN nearcountry.country_code;
  END LOOP;

  RETURN NULL;
END;
$$
LANGUAGE plpgsql IMMUTABLE;

CREATE OR REPLACE FUNCTION get_partition(in_country_code character varying(2)) RETURNS INTEGER
  AS $$
DECLARE
  nearcountry RECORD;
BEGIN
  FOR nearcountry IN select partition from country_name where country_code = in_country_code
  LOOP
    RETURN nearcountry.partition;
  END LOOP;
  RETURN 0;
END;
$$
LANGUAGE plpgsql IMMUTABLE;


CREATE OR REPLACE FUNCTION determineRankPartitionCode(type character varying ,geom geometry,osm_id bigint, country_code character varying)
RETURNS rankPartitionCode AS $$
DECLARE
  place_centroid GEOMETRY;
  result rankPartitionCode;
BEGIN
    --RAISE NOTICE 'determine rank with type % and osm_id %', type, osm_id;
    place_centroid := ST_PointOnSurface(geom);
    IF (osm_id IS NULL) THEN
    result.rank_search := rank_address(type);
  ELSE
    result.rank_search := rank_place(type, osm_id);
  END IF;
    -- recalculate country and partition
    IF result.rank_search = 4 THEN
      -- for countries, believe the mapped country code,
      -- so that we remain in the right partition if the boundaries
      -- suddenly expand.
      result.partition := get_partition(lower(country_code));
      IF result.partition = 0 THEN
        result.calculated_country_code := lower(get_country_code(place_centroid));
        result.partition := get_partition(result.calculated_country_code);
      ELSE
        result.calculated_country_code := lower(country_code);
      END IF;
    ELSE
      IF result.rank_search > 4 THEN
        result.calculated_country_code := lower(get_country_code(place_centroid));
        result.partition := get_partition(result.calculated_country_code);
      END IF;
    END IF;
    RETURN result;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION determinePartitionFromImportedData(geom geometry)
RETURNS INTEGER AS $$
DECLARE
  result INTEGER;
BEGIN
  SELECT partition, calculated_country_code from osm_polygon where ST_Within(ST_PointOnSurface(geom), geometry) AND rank_search = 4 AND NOT partition = 0 INTO result;
    RETURN result;
END;
$$ LANGUAGE plpgsql;
