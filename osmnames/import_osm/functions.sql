/* See Nominatim functions.sql placex_insert() line 676 for determining ranks
   Reference: https://github.com/openstreetmap/Nominatim/blob/master/sql/functions.sql */
DROP FUNCTION IF EXISTS get_place_rank(TEXT, BIGINT);
CREATE FUNCTION get_place_rank(type TEXT, osm_id_in BIGINT)
RETURNS int AS $$
BEGIN
  RETURN CASE
    WHEN type IN ('administrative') AND osm_id_in IS NULL THEN 30
    WHEN type IN ('administrative') THEN 2*(SELECT COALESCE(admin_level,15) FROM osm_polygon WHERE osm_id = osm_id_in)
    WHEN type IN ('continent','sea','ocean') THEN 2
    WHEN type IN ('country') THEN 4
    WHEN type IN ('state') THEN 8
    WHEN type IN ('county') THEN 12
    WHEN type IN ('city','water','desert') THEN 16
    WHEN type IN ('island','bay','river') THEN 17
    WHEN type IN ('region','peak','volcano') THEN 18 -- region dropped from previous value of 10
    WHEN type IN ('town') THEN 18
    WHEN type IN ('village','hamlet','municipality','district','unincorporated_area','borough') THEN 19
    WHEN type IN ('suburb','croft','subdivision','isolated_dwelling','farm','locality','islet','mountain_pass','hill') THEN 20
    WHEN type IN ('neighbourhood', 'residential','reservoir','stream') THEN 22
    WHEN type IN ('motorway','trunk','primary','secondary','tertiary','unclassified','residential','road','living_street','raceway','construction','track','crossing',
                  'riverbank','canal') THEN 26 WHEN type IN ('motorway_link','trunk_link','primary_link','secondary_link','tertiary_link','service','path','cycleway','steps','bridleway','footway','corridor') THEN 27
    WHEN type IN ('houses') THEN 28
    WHEN type IN ('house','building','drain','ditch') THEN 30
    WHEN type IN ('quarter') THEN 30
  END;
END;
$$ LANGUAGE plpgsql IMMUTABLE;


DROP FUNCTION IF EXISTS set_country_code_for_containing_entities(VARCHAR(2), geometry);
CREATE FUNCTION set_country_code_for_containing_entities(country_code_in VARCHAR(2), geometry_value GEOMETRY) RETURNS VOID AS $$
BEGIN
  UPDATE osm_linestring SET country_code = country_code_in WHERE country_code IS NULL
                                                                 AND ST_CONTAINS(geometry_value, geometry);

  UPDATE osm_point SET country_code = country_code_in WHERE country_code IS NULL
                                                            AND ST_CONTAINS(geometry_value, geometry);

  UPDATE osm_polygon SET country_code = country_code_in WHERE country_code IS NULL
                                                              AND ST_CONTAINS(geometry_value, geometry);

  UPDATE osm_housenumber SET country_code = country_code_in WHERE country_code IS NULL
                                                                  AND ST_CONTAINS(geometry_value, geometry);
END;
$$ LANGUAGE plpgsql;


DROP FUNCTION IF EXISTS set_parent_id_for_containing_entities(BIGINT, INT, geometry);
CREATE FUNCTION set_parent_id_for_containing_entities(id_in BIGINT, admin_level_in INT, geometry_value GEOMETRY) RETURNS VOID AS $$
BEGIN
  UPDATE osm_linestring SET parent_id = id_in WHERE parent_id IS NULL
                                                    AND id_in != id
                                                    AND ST_Contains(geometry_value, geometry);

  UPDATE osm_polygon SET parent_id = id_in WHERE parent_id IS NULL
                                                 AND id_in != id
                                                 AND admin_level > admin_level_in
                                                 AND ST_Contains(geometry_value, geometry);

  UPDATE osm_housenumber SET parent_id = id_in WHERE parent_id IS NULL
                                                     AND id_in != id
                                                     AND ST_Contains(geometry_value, geometry);

  UPDATE osm_point SET parent_id = id_in WHERE parent_id IS NULL
                                               AND id_in != id
                                               AND ST_Contains(geometry_value, geometry);
END;
$$ LANGUAGE plpgsql;
