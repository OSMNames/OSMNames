DROP FUNCTION IF EXISTS set_parent_id_for_elements_within_geometry(BIGINT, INT, geometry);
CREATE FUNCTION set_parent_id_for_elements_within_geometry(id_in BIGINT, admin_level_in INT, geometry_in GEOMETRY) RETURNS VOID AS $$
BEGIN
  UPDATE osm_linestring SET parent_id = id_in WHERE parent_id IS NULL
                                                    AND id_in != id
                                                    AND st_contains(geometry_in, geometry);

  UPDATE osm_polygon SET parent_id = id_in WHERE parent_id IS NULL
                                                 AND id_in != id
                                                 AND st_contains(geometry_in, geometry)
                                                 AND COALESCE(admin_level, 100) > COALESCE(admin_level_in, -1);

  UPDATE osm_housenumber SET parent_id = id_in WHERE parent_id IS NULL
                                                     AND id_in != id
                                                     AND st_contains(geometry_in, geometry);

  UPDATE osm_point SET parent_id = id_in WHERE parent_id IS NULL
                                               AND id_in != id
                                               AND st_contains(geometry_in, geometry);
END;
$$ LANGUAGE plpgsql;

CREATE INDEX IF NOT EXISTS idx_osm_linestring_parent_id ON osm_linestring(parent_id);
CREATE INDEX IF NOT EXISTS idx_osm_polygon_parent_id ON osm_polygon(parent_id);
CREATE INDEX IF NOT EXISTS idx_osm_housenumber_parent_id ON osm_housenumber(parent_id);
CREATE INDEX IF NOT EXISTS idx_osm_point_parent_id ON osm_point(parent_id);

DO $$
BEGIN
  PERFORM set_parent_id_for_elements_within_geometry(id, admin_level, geometry)
          FROM osm_polygon
          WHERE type NOT IN ('water', 'bay', 'reservoir', 'desert')
          ORDER BY place_rank DESC;
END
$$ LANGUAGE plpgsql;
