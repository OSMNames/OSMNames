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
	END;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

CREATE OR REPLACE FUNCTION city_class(type TEXT)
RETURNS TEXT AS $$
BEGIN
	RETURN CASE
		WHEN type IN ('administrative', 'postal_code') THEN 'boundary'
		WHEN type IN ('city','borough','suburb','quarter','neighbourhood','town','village','hamlet') THEN 'place'
	END;
END;
$$ LANGUAGE plpgsql IMMUTABLE;


CREATE OR REPLACE FUNCTION countryCode(country_id int) returns TEXT as $$
	SELECT country_code FROM osm_city_polygon WHERE id = country_id;
$$ language 'sql';

CREATE OR REPLACE FUNCTION placeName(place_id int) returns TEXT as $$
	SELECT COALESCE(NULLIF(name_en,''), name) FROM osm_city_polygon WHERE id = place_id;
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
      retVal := array_append(retVal, (SELECT COALESCE(NULLIF(name_en,''), name)::character varying FROM osm_city_polygon WHERE id = x));
    END LOOP;
END IF;
RETURN retVal;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION updateParentCountry(parentID int) RETURNS void AS $$
BEGIN

UPDATE osm_city_polygon SET country = parentID FROM 
(SELECT id, country FROM osm_city_polygon WHERE parent_ids @> ARRAY[parentID]::int[]) AS countryQuery 
WHERE osm_city_polygon.id = countryQuery.id;

UPDATE osm_city_point SET country = parentID FROM 
(SELECT id, country FROM osm_city_point WHERE parent_ids @> ARRAY[parentID]::int[]) AS countryQuery 
WHERE osm_city_point.id = countryQuery.id;

UPDATE osm_road_linestring SET country = parentID FROM 
(SELECT id, country FROM osm_road_linestring WHERE parent_ids @> ARRAY[parentID]::int[]) AS countryQuery 
WHERE osm_road_linestring.id = countryQuery.id;

END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION updateParentState(parentID int) RETURNS void AS $$
BEGIN

UPDATE osm_city_polygon SET state = parentID FROM 
(SELECT id, state FROM osm_city_polygon WHERE parent_ids @> ARRAY[parentID]::int[]) AS stateQuery 
WHERE osm_city_polygon.id = stateQuery.id;

UPDATE osm_city_point SET state = parentID FROM 
(SELECT id, state FROM osm_city_point WHERE parent_ids @> ARRAY[parentID]::int[]) AS stateQuery 
WHERE osm_city_point.id = stateQuery.id;

UPDATE osm_road_linestring SET state = parentID FROM 
(SELECT id, state FROM osm_road_linestring WHERE parent_ids @> ARRAY[parentID]::int[]) AS stateQuery 
WHERE osm_road_linestring.id = stateQuery.id;

END;
$$ LANGUAGE plpgsql;