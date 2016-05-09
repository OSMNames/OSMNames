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
      retVal := array_append(retVal, (SELECT name FROM osm_city_polygon WHERE id = x));
    END LOOP;
  RETURN retVal;
ELSE
    RETURN NULL;
END IF;

END;
$$ LANGUAGE plpgsql;