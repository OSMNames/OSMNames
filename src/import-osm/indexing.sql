CREATE OR REPLACE FUNCTION rank_place(type TEXT, osmID bigint)
RETURNS int AS $$
BEGIN
	RETURN CASE
		WHEN type IN ('administrative') THEN 2*(SELECT admin_level FROM osm_city_polygon o WHERE osm_id = osmID)  
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
		WHEN type IN ('neighbourhood') THEN 22
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

-- Alter tables for parent ids calculation
ALTER TABLE osm_city_polygon ADD COLUMN parent_ids integer[];
ALTER TABLE osm_city_point ADD COLUMN parent_ids integer[];
ALTER TABLE osm_road_linestring ADD COLUMN parent_ids integer[];


UPDATE osm_city_polygon SET rank_search = rank_place(type, osm_id);
UPDATE osm_city_point SET rank_search = rank_place(type, osm_id);
UPDATE osm_road_linestring SET rank_search = rank_address(type, osm_id);


UPDATE osm_city_polygon
  SET parent_ids = calculated_parent_ids
FROM (SELECT pl.id as currentID, array_agg(area.id ORDER BY area.rank_search DESC) as calculated_parent_ids
FROM osm_city_polygon area, osm_city_polygon pl 
WHERE ST_Contains(area.geometry, pl.geometry) 
GROUP BY pl.id
ORDER BY pl.id) AS spatialQuery 
WHERE osm_city_polygon.id = currentID;

UPDATE osm_city_point
  SET parent_ids = calculated_parent_ids
FROM (SELECT pl.id as currentID, array_agg(area.id ORDER BY area.rank_search DESC) as calculated_parent_ids
FROM osm_city_polygon area, osm_city_point pl 
WHERE ST_Contains(area.geometry, pl.geometry) 
GROUP BY pl.id
ORDER BY pl.id) AS spatialQuery 
WHERE osm_city_point.id = currentID;

UPDATE osm_road_linestring
  SET parent_ids = calculated_parent_ids
FROM (SELECT pl.id as currentID, array_agg(area.id ORDER BY area.rank_search DESC) as calculated_parent_ids
FROM osm_city_polygon area, osm_road_linestring pl 
WHERE ST_Contains(area.geometry, pl.geometry) 
GROUP BY pl.id
ORDER BY pl.id) AS spatialQuery 
WHERE osm_road_linestring.id = currentID;

-- TODO change order, partition into countries first and then run spatial queries
SELECT updateParentCountry(id) FROM osm_city_polygon WHERE rank_search = 4;
SELECT updateParentState(id) FROM osm_city_polygon WHERE rank_search = 8;
