DROP FUNCTION IF EXISTS set_parent_id_for_elements_within_geometry(BIGINT, INT, geometry);
CREATE FUNCTION set_parent_id_for_elements_within_geometry(id_in BIGINT, admin_level_in INT, geometry_in GEOMETRY)
RETURNS VOID AS $$
BEGIN
  UPDATE osm_polygon SET parent_id = id_in WHERE parent_id IS NULL
                                                 AND id_in != id
                                                 AND st_contains(geometry_in, geometry)
                                                 AND COALESCE(admin_level, 100) > COALESCE(admin_level_in, -1);

  UPDATE osm_housenumber_point SET parent_id = id_in WHERE parent_id IS NULL
                                                           AND id_in != id
                                                           AND st_contains(geometry_in, geometry);

  UPDATE osm_housenumber_linestring SET parent_id = id_in WHERE parent_id IS NULL
                                                                AND id_in != id
                                                                AND st_contains(geometry_in, geometry);

  UPDATE osm_point SET parent_id = id_in WHERE parent_id IS NULL
                                               AND id_in != id
                                               AND st_contains(geometry_in, geometry)
                                               AND linked IS FALSE;
  IF admin_level_in >= 6 THEN
    UPDATE osm_linestring SET parent_id = id_in WHERE parent_id IS NULL
                                                      AND id_in != id
                                                      AND st_contains(geometry_in, geometry);
  END IF;
END;
$$ LANGUAGE plpgsql;

DROP FUNCTION IF EXISTS get_most_intersecting_parent_id(BIGINT, geometry, INT);
CREATE FUNCTION get_most_intersecting_parent_id(id_in BIGINT, geometry_in GEOMETRY, admin_level_in INT)
RETURNS BIGINT AS $$
DECLARE
  parent_id BIGINT;
BEGIN
  SELECT id FROM osm_polygon WHERE id != id_in
                                   AND st_intersects(geometry, geometry_in)
                                   AND st_area(geometry) > st_area(geometry_in)
                                   AND place_rank <= 22
                                   AND COALESCE(admin_level, 100) < COALESCE(admin_level_in, -1)
                                   AND type NOT IN ('water', 'desert', 'bay', 'reservoir')
                                   ORDER BY place_rank DESC,
                                            st_area(st_intersection(geometry, geometry_in)) DESC,
                                            st_length(st_intersection(geometry, geometry_in)) DESC
                                   LIMIT 1
                                   INTO parent_id;
  RETURN parent_id;
END;
$$ LANGUAGE plpgsql;

CLUSTER osm_linestring_geom ON osm_linestring;
CLUSTER osm_polygon_geom ON osm_polygon;
CLUSTER osm_housenumber_point_geom ON osm_housenumber_point;
CLUSTER osm_housenumber_linestring_geom ON osm_housenumber_linestring;
CLUSTER osm_point_geom ON osm_point;

CREATE INDEX IF NOT EXISTS idx_osm_polygon_admin_level ON osm_polygon(admin_level);
CREATE INDEX IF NOT EXISTS idx_osm_polygon_type ON osm_polygon(type) WHERE type NOT IN ('water', 'desert', 'bay', 'reservoir');
CREATE INDEX IF NOT EXISTS idx_osm_polygon_parent_id ON osm_polygon(parent_id);

-- set parent ids (fast)
DO $$
BEGIN
  PERFORM set_parent_id_for_elements_within_geometry(id, admin_level, geometry)
          FROM osm_polygon
          WHERE place_rank <= 22 AND type NOT IN ('water', 'desert', 'bay', 'reservoir')
          ORDER BY place_rank DESC;
END
$$ LANGUAGE plpgsql;

-- set parent ids by most intersecting polygons (slow)
UPDATE osm_polygon SET parent_id = get_most_intersecting_parent_id(id, geometry, admin_level) WHERE parent_id IS NULL;
UPDATE osm_linestring SET parent_id = get_most_intersecting_parent_id(id, geometry, NULL) WHERE parent_id IS NULL;
