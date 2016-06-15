CREATE OR REPLACE FUNCTION road_class(type TEXT)
RETURNS TEXT AS $$
BEGIN
	RETURN CASE
		WHEN type IN ('tertiary') THEN 'tertiary'
		WHEN type IN ('trunk') THEN 'trunk'
		WHEN type IN ('steps','corridor','crossing','piste','mtb','hiking','cycleway','footway','path','bridleway') THEN 'path'
		WHEN type IN ('platform') THEN 'pedestrian'
		WHEN type IN ('secondary') THEN 'secondary'
		WHEN type IN ('service') THEN 'service'
		WHEN type IN ('construction') THEN 'construction'
		WHEN type IN ('track') THEN 'track'
		WHEN type IN ('primary') THEN 'primary'
		WHEN type IN ('motorway') THEN 'motorway'
		WHEN type IN ('rail','light_rail','subway') THEN 'major_rail'
		WHEN type IN ('hole') THEN 'golf'
		WHEN type IN ('cable_car','gondola','mixed_lift','chair_lift','drag_lift','t-bar','j-bar','platter','rope_tow','zip_line','magic_carpet','canopy') THEN 'aerialway'
		WHEN type IN ('motorway_link') THEN 'motorway_link'
		WHEN type IN ('ferry') THEN 'ferry'
		WHEN type IN ('trunk_link','primary_link','secondary_link','tertiary_link') THEN 'link'
		WHEN type IN ('unclassified','residential','road','living_street','raceway') THEN 'street'
		ELSE 'multiple'
	END;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

CREATE OR REPLACE FUNCTION city_class(type TEXT)
RETURNS TEXT AS $$
BEGIN
	RETURN CASE
		WHEN type IN ('administrative', 'postal_code') THEN 'boundary'
		WHEN type IN ('city','borough','suburb','quarter','neighbourhood','town','village','hamlet') THEN 'place'
		WHEN type IN ('residential') THEN 'landuse'
	END;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

CREATE OR REPLACE FUNCTION rank_place(type TEXT, osmID bigint)
RETURNS int AS $$
BEGIN
	RETURN CASE
		WHEN type IN ('administrative') THEN 2*(SELECT COALESCE(admin_level,15) FROM osm_polygon o WHERE osm_id = osmID)  
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

CREATE OR REPLACE FUNCTION rank_address(type TEXT, osmID bigint)
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


CREATE OR REPLACE FUNCTION countryName(partition_id int) returns TEXT as $$
	SELECT COALESCE(name -> 'name:en',name -> 'name') FROM country_name WHERE partition = partition_id;
$$ language 'sql';


CREATE OR REPLACE FUNCTION getHierarchyAsTextArray(int[])
RETURNS character varying[] AS $$
DECLARE
  retVal character varying[];
  x int;
BEGIN
IF $1 IS NOT NULL
THEN
    FOREACH x IN ARRAY $1
    LOOP
      retVal := array_append(retVal, (SELECT COALESCE(NULLIF(name_en,''), name)::character varying FROM osm_polygon WHERE id = x));
    END LOOP;
END IF;
RETURN retVal;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION constructDisplayName(id_value BIGINT, delimiter TEXT) RETURNS TEXT AS $$
DECLARE
  displayName TEXT;
  oldName TEXT;
  currentName TEXT;
  current_id BIGINT;
BEGIN
  current_id := id_value;
  WHILE current_id IS NOT NULL LOOP
    SELECT parent_id, COALESCE(NULLIF(name_en,''), name) FROM osm_polygon WHERE id = current_id INTO current_id, currentName;
    IF displayName IS NULL THEN
	displayName := currentName;
    ELSE
    	displayName := displayName || delimiter || ' ' || currentName;
    END IF;
  END LOOP;
RETURN displayName;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION constructNodeDisplayName(id_value BIGINT, delimiter TEXT, name TEXT) RETURNS TEXT AS $$
DECLARE
  displayName TEXT;
BEGIN
	SELECT constructDisplayName(id_value,',') INTO displayName;
	displayName := name || delimiter || ' ' || displayName;
	IF displayName IS NULL THEN
		return '';
	END IF;
RETURN displayName;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION constructSpecificParentName(id_value BIGINT, from_rank INTEGER, to_rank INTEGER) RETURNS TEXT AS $$
DECLARE
  current_id BIGINT;
  currentName TEXT;
  currentNameOld TEXT;
  current_rank INTEGER;
BEGIN
  current_rank := from_rank;
  current_id := id_value;
  currentName := '';
  currentNameOld := '';
  IF current_rank = to_rank THEN
    SELECT COALESCE(NULLIF(name_en,''), name) FROM osm_polygon WHERE id = current_id INTO currentName;
    RETURN currentName;
  END IF; 
  WHILE current_rank > to_rank  LOOP
  currentNameOld := currentName;
    SELECT parent_id, COALESCE(NULLIF(name_en,''), name), rank_search FROM osm_polygon WHERE id = current_id INTO current_id, currentName, current_rank;
    IF current_id IS NULL THEN
	RETURN '';
    END IF; 
      IF current_rank < to_rank THEN
	RETURN currentNameOld;
    END IF; 
  END LOOP;
RETURN currentName;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION determineParentPlace(id_value BIGINT, partition_value INT, rank_search_value INT, geometry_value GEOMETRY) RETURNS BIGINT AS $$
DECLARE
  retVal BIGINT;
BEGIN
  FOR current_rank  IN REVERSE rank_search_value..1 LOOP
     SELECT id FROM osm_polygon WHERE partition=partition_value AND rank_search = current_rank AND NOT id=id_value AND ST_Contains(geometry, geometry_value) INTO retVal;
     IF retVal IS NOT NULL THEN
      return retVal;
    END IF;
  END LOOP;
RETURN retVal;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION findRoadsWithinGeometry(id_value integer,partition_value integer, geometry_value GEOMETRY) RETURNS VOID AS $$
BEGIN
	UPDATE osm_linestring SET parent_id = id_value WHERE parent_id IS NULL AND ST_Contains(geometry_value,geometry);
--	UPDATE osm_linestring SET parent_id = id_value WHERE parent_id IS NULL AND (ST_Contains(geometry_value,geometry) OR ST_Intersects(geometry_value,geometry));
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

CREATE OR REPLACE FUNCTION getImportance(rank_search int, wikipedia character varying, country_code VARCHAR(2)) returns double precision as $$

DECLARE
  langs TEXT[];
  i INT;
  wiki_article_title TEXT;
  wiki_article_language TEXT;
  result double precision;
BEGIN

  wiki_article_title := replace(split_part(wikipedia, ':', 2),' ','_');
  wiki_article_language := split_part(wikipedia, ':', 1);

  SELECT importance FROM wikipedia_article WHERE language = wiki_article_language AND title = wiki_article_title ORDER BY importance DESC LIMIT 1 INTO result;
  IF result IS NOT NULL THEN
    return result;
  END IF;

  langs := ARRAY['english','country','ar','bg','ca','cs','da','de','en','es','eo','eu','fa','fr','ko','hi','hr','id','it','he','lt','hu','ms','nl','ja','no','pl','pt','kk','ro','ru','sk','sl','sr','fi','sv','tr','uk','vi','vo','war','zh'];
  i := 1;

  WHILE langs[i] IS NOT NULL LOOP

	-- try default language for this country, English and then every other language for possible match
    wiki_article_language := CASE WHEN langs[i] = 'english' THEN 'en' WHEN langs[i] = 'country' THEN get_country_language_code(country_code) ELSE langs[i] END;

  SELECT importance FROM wikipedia_article WHERE language = wiki_article_language AND title = wiki_article_title ORDER BY importance DESC LIMIT 1 INTO result;
    IF result IS NOT NULL THEN
      return result;
    END IF;

      IF result IS NOT NULL THEN
        return result;
      END IF;
    i := i + 1;
  END LOOP;
  -- return default calculated value if no match found  
    IF rank_search IS NOT NULL THEN
      return 0.75-(rank_search::double precision/40);
    END IF;
  RETURN NULL;
END;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION getWikipediaURL(wikipedia character varying, country_code VARCHAR(2)) returns TEXT as $$
DECLARE
  langs TEXT[];
  i INT;
  wiki_article_title TEXT;
  wiki_article_language TEXT;
  wiki_url_part TEXT;
BEGIN
  IF wikipedia IS NULL OR wikipedia <> '' IS FALSE THEN
  	RETURN '';
  END IF;
  wiki_url_part := '.wikipedia.org/wiki/';
  wiki_article_title := replace(split_part(wikipedia, ':', 2),' ','_');
  wiki_article_language := split_part(wikipedia, ':', 1);

  RETURN wiki_article_language || wiki_url_part || wiki_article_title;
END;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION mergeStreetsOfParentId(parent_id_value bigint) RETURNS void AS $$
BEGIN
	--RAISE NOTICE 'merging streets of parent with id %', parent_id_value;
	INSERT INTO osm_merged_multi_linestring(member_ids, type, name, name_fr, name_en, name_de, name_es, name_ru, name_zh, wikipedia, geometry, partition, calculated_country_code, rank_search, parent_id) 
	SELECT array_agg(DISTINCT sub.id), string_agg(DISTINCT type,','), sub.name, max(sub.name_fr), max(sub.name_en), max(sub.name_de), max(sub.name_es), max(sub.name_ru), max(sub.name_zh), max(sub.wikipedia),  ST_UNION(sub.geometry), bit_and(sub.partition), max(sub.calculated_country_code), min(sub.rank_search), parent_id_value FROM
	(SELECT  a.id, a.type, a.name, a.name_fr, a.name_en, a.name_de, a.name_es, a.name_ru, a.name_zh, a.wikipedia, a.geometry, a.partition, a.calculated_country_code, a.rank_search FROM
	osm_linestring AS a INNER JOIN osm_linestring AS b 
	ON ST_Touches(a.geometry, b.geometry)
	WHERE a.parent_id = parent_id_value AND b.parent_id=parent_id_value AND a.name = b.name AND a.id!=b.id) AS sub
	GROUP BY sub.name ;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION mergeStreetsOfParentId(parent_id_value bigint, rowNumber bigint, sumOfRows bigint) RETURNS void AS $$
BEGIN
	RAISE NOTICE '% / % , merging streets of parent with id %', rowNumber, sumOfRows, parent_id_value;
	INSERT INTO osm_merged_multi_linestring(member_ids, type, name, name_fr, name_en, name_de, name_es, name_ru, name_zh, wikipedia, geometry, partition, calculated_country_code, rank_search, parent_id) 
	SELECT array_agg(DISTINCT sub.id), string_agg(DISTINCT type,','), sub.name, max(sub.name_fr), max(sub.name_en), max(sub.name_de), max(sub.name_es), max(sub.name_ru), max(sub.name_zh), max(sub.wikipedia),  ST_UNION(sub.geometry), bit_and(sub.partition), max(sub.calculated_country_code), min(sub.rank_search), parent_id_value FROM
	(SELECT  a.id, a.type, a.name, a.name_fr, a.name_en, a.name_de, a.name_es, a.name_ru, a.name_zh, a.wikipedia, a.geometry, a.partition, a.calculated_country_code, a.rank_search FROM
	osm_linestring AS a INNER JOIN osm_linestring AS b 
	ON ST_Touches(a.geometry, b.geometry)
	WHERE a.parent_id = parent_id_value AND b.parent_id=parent_id_value AND a.name = b.name AND a.id!=b.id) AS sub
	GROUP BY sub.name ;
END;
$$ LANGUAGE plpgsql;
    
CREATE OR REPLACE FUNCTION updateMergedFlag() RETURNS TRIGGER AS $$
DECLARE
	member_id BIGINT;
BEGIN
	IF NEW.member_ids IS NOT NULL THEN
		FOREACH member_id IN ARRAY NEW.member_ids LOOP
			UPDATE osm_linestring SET merged = TRUE WHERE id=member_id;
		END LOOP;
	END IF;
	return NEW;
END;
$$ LANGUAGE plpgsql;