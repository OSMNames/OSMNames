CREATE OR REPLACE FUNCTION rank_place(type TEXT, osmID bigint)
RETURNS int AS $$
BEGIN
	RETURN CASE
		WHEN type IN ('administrative') THEN 2*(SELECT admin_level FROM osm_polygon o WHERE osm_id = osmID)  
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


--cleanup unusable entries
DELETE FROM osm_polygon WHERE (name <> '' OR name_fr <> '' OR name_en <> '' OR name_de <> '' OR name_es <> '' OR name_ru <> '' OR name_zh <> '') IS FALSE;
DELETE FROM osm_point WHERE (name <> '' OR name_fr <> '' OR name_en <> '' OR name_de <> '' OR name_es <> '' OR name_ru <> '' OR name_zh <> '') IS FALSE;
--DELETE FROM osm_linestring WHERE (name <> '' OR name_fr <> '' OR name_en <> '' OR name_de <> '' OR name_es <> '' OR name_ru <> '' OR name_zh <> '') IS FALSE;


-- Alter tables for parent ids calculation
ALTER TABLE osm_polygon 
	ADD COLUMN partition integer,
	ADD COLUMN calculated_country_code character varying(2),
	ADD COLUMN linked_osm_id bigint,
	ADD COLUMN rank_search int,
	ADD COLUMN parent_ids integer[],
	ADD COLUMN parent_id bigint,
	ADD COLUMN parent_type int;
ALTER TABLE osm_point
	ADD COLUMN partition integer,
	ADD COLUMN calculated_country_code character varying(2),
	ADD COLUMN rank_search int,
	ADD COLUMN parent_ids integer[],
	ADD COLUMN linked BOOLEAN DEFAULT FALSE,
	ADD COLUMN parent_id bigint,
	ADD COLUMN parent_type int;ALTER TABLE osm_linestring
	ADD COLUMN partition integer,
	ADD COLUMN calculated_country_code character varying(2),
	ADD COLUMN linked_osm_id bigint,
	ADD COLUMN rank_search int,
	ADD COLUMN parent_ids integer[],
	ADD COLUMN parent_id bigint,
	ADD COLUMN parent_type int;

--create triggers for partitioning
CREATE TRIGGER performCountryAndPartitionUpdate_polygon
    BEFORE UPDATE OF rank_search ON osm_polygon
    FOR EACH ROW
    EXECUTE PROCEDURE determineCountryCodeAndPartition();

CREATE TRIGGER performCountryAndPartitionUpdate_point
    BEFORE UPDATE OF rank_search ON osm_point
    FOR EACH ROW
    EXECUTE PROCEDURE determineCountryCodeAndPartition();

CREATE TRIGGER performCountryAndPartitionUpdate_linestring
    BEFORE UPDATE OF rank_search ON osm_linestring
    FOR EACH ROW
    EXECUTE PROCEDURE determineCountryCodeAndPartition();

--do the ranking and partitioning
UPDATE osm_polygon SET rank_search = rank_place(type, osm_id);
UPDATE osm_point SET rank_search = rank_place(type, osm_id);
UPDATE osm_linestring SET rank_search = rank_address(type, osm_id);

--determine linked places
-- places with admin_centre tag
UPDATE osm_polygon p
	SET linked_osm_id = r.member         
	FROM osm_relation r                                     
	WHERE 
	r.type = 0 AND r.role = 'admin_centre' 
	AND p.osm_id = r.osm_id;    

-- places with label tag inside geometry
UPDATE osm_polygon p
	SET linked_osm_id = n.osm_id 
	FROM osm_point  n, osm_polygon r WHERE n.name = r.name AND ST_WITHIN(n.geometry,r.geometry)
	AND p.osm_id = r.osm_id      
	AND r.osm_id NOT IN (
	SELECT osm_id 
	FROM osm_relation
	WHERE role = 'label');  

--tag linked places
UPDATE osm_point p SET linked = TRUE
	FROM osm_point po WHERE po.osm_id IN (SELECT linked_osm_id FROM osm_polygon WHERE linked_osm_id IS NOT NULL)
	AND po.osm_id = p.osm_id;


--determine parents
UPDATE osm_polygon SET parent_id = determineParentPlace(id, partition, rank_search, geometry);
UPDATE osm_point SET parent_id = determineParentPlace(id, partition, rank_search, geometry) WHERE linked IS FALSE;
SELECT determineRoadHierarchyForEachCountry();

--determine parents
/*
UPDATE osm_polygon
  SET parent_ids = calculated_parent_ids
FROM (SELECT pl.id as currentID, array_agg(area.id ORDER BY area.rank_search DESC) as calculated_parent_ids
FROM osm_polygon area, osm_polygon pl 
WHERE ST_Contains(area.geometry, pl.geometry) 
GROUP BY pl.id
ORDER BY pl.id) AS spatialQuery 
WHERE osm_polygon.id = currentID;

UPDATE osm_point
  SET parent_ids = calculated_parent_ids
FROM (SELECT pl.id as currentID, array_agg(area.id ORDER BY area.rank_search DESC) as calculated_parent_ids
FROM osm_polygon area, osm_point pl 
WHERE ST_Contains(area.geometry, pl.geometry) 
GROUP BY pl.id
ORDER BY pl.id) AS spatialQuery 
WHERE osm_point.id = currentID;

UPDATE osm_linestring
  SET parent_ids = calculated_parent_ids
FROM (SELECT pl.id as currentID, array_agg(area.id ORDER BY area.rank_search DESC) as calculated_parent_ids
FROM osm_polygon area, osm_linestring pl 
WHERE ST_Contains(area.geometry, pl.geometry) 
GROUP BY pl.id
ORDER BY pl.id) AS spatialQuery 
WHERE osm_linestring.id = currentID;
*/

