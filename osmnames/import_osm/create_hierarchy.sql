DROP FUNCTION IF EXISTS set_parent_id_for_containing_entities(BIGINT, INT, VARCHAR(2), geometry);
CREATE FUNCTION set_parent_id_for_containing_entities(id_in BIGINT, admin_level_in INT, country_code_in VARCHAR(2), geometry_in GEOMETRY) RETURNS VOID AS $$
BEGIN
  UPDATE osm_linestring SET parent_id = id_in WHERE parent_id IS NULL
                                                    AND id_in != id
                                                    AND country_code = country_code_in
                                                    AND st_contains(geometry_in, geometry);

  UPDATE osm_polygon SET parent_id = id_in WHERE parent_id IS NULL
                                                 AND id_in != id
                                                 AND admin_level > admin_level_in
                                                 AND country_code = country_code_in
                                                 AND st_contains(geometry_in, geometry);

  UPDATE osm_housenumber SET parent_id = id_in WHERE parent_id IS NULL
                                                     AND id_in != id
                                                     AND country_code = country_code_in
                                                     AND st_contains(geometry_in, geometry);

  UPDATE osm_point SET parent_id = id_in WHERE parent_id IS NULL
                                               AND id_in != id
                                               AND country_code = country_code_in
                                               AND st_contains(geometry_in, geometry);
END;
$$ LANGUAGE plpgsql;

DO $$
BEGIN
  PERFORM set_parent_id_for_containing_entities(id, admin_level, country_code, geometry)
          FROM osm_polygon
          WHERE place_rank <= 22 AND
                type not in ('water', 'desert', 'bay', 'reservoir')
          ORDER BY place_rank DESC;
END
$$ LANGUAGE plpgsql;
