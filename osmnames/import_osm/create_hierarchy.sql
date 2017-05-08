DROP FUNCTION IF EXISTS set_parent_id_for_elements_within_geometry(BIGINT, INT, VARCHAR(2), geometry);
CREATE FUNCTION set_parent_id_for_elements_within_geometry(id_in BIGINT, admin_level_in INT, country_code_in VARCHAR(2), geometry_in GEOMETRY) RETURNS VOID AS $$
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
                                               AND st_contains(geometry_in, geometry)
                                               AND linked IS FALSE;
END;
$$ LANGUAGE plpgsql;

CREATE INDEX IF NOT EXISTS idx_osm_linestring_parent_id ON osm_linestring(parent_id);
CREATE INDEX IF NOT EXISTS idx_osm_polygon_parent_id ON osm_polygon(parent_id);
CREATE INDEX IF NOT EXISTS idx_osm_housenumber_parent_id ON osm_housenumber(parent_id);
CREATE INDEX IF NOT EXISTS idx_osm_point_parent_id ON osm_point(parent_id);

CREATE INDEX IF NOT EXISTS idx_osm_polygon_admin_level ON osm_polygon(admin_level);

DO $$
BEGIN
  PERFORM set_parent_id_for_elements_within_geometry(id, admin_level, country_code, geometry)
          FROM osm_polygon
          WHERE place_rank <= 22
            AND type IN ('administrative', 'continent', 'country', 'state',
              'county', 'city', 'island', 'region', 'town', 'village', 'hamlet',
              'municipality', 'district', 'unincorporated_area', 'borough',
              'suburb', 'croft', 'subdivision', 'isolated_dwelling', 'farm',
              'locality', 'neighbourhood', 'residential')
          ORDER BY place_rank DESC;
END
$$ LANGUAGE plpgsql;
