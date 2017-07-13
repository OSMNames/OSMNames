DROP FUNCTION IF EXISTS set_parent_id_for_elements_within_geometry(BIGINT, INT, geometry);
CREATE FUNCTION set_parent_id_for_elements_within_geometry(id_in BIGINT, admin_level_in INT, geometry_in GEOMETRY)
RETURNS VOID AS $$
BEGIN
  UPDATE osm_polygon SET parent_id = id_in WHERE parent_id IS NULL
                                                 AND id_in != id
                                                 AND st_contains(geometry_in, geometry)
                                                 AND COALESCE(admin_level, 100) > COALESCE(admin_level_in, -1);

  UPDATE osm_housenumber SET parent_id = id_in WHERE parent_id IS NULL
                                                     AND id_in != id
                                                     AND st_contains(geometry_in, geometry);

  UPDATE osm_point SET parent_id = id_in WHERE parent_id IS NULL
                                               AND id_in != id
                                               AND st_contains(geometry_in, geometry)
                                               AND linked IS FALSE;


  -- setting the parent_id of linestrings makes only sense when the polygons admin_level is >= 10
  -- Because a linestring is likely to intersect multiple polygons with high admin_levels,
  -- it will only be fully covered by a polygon with a small admin_level, which is not the correct parent.
  -- The parent for the remaining linestrings will be set later
  IF admin_level_in >= 10 THEN
    UPDATE osm_linestring SET parent_id = id_in WHERE parent_id IS NULL
                                                      AND id_in != id
                                                      AND st_contains(geometry_in, geometry);
  END IF;
END;
$$ LANGUAGE plpgsql;

DO $$
BEGIN
  PERFORM set_parent_id_for_elements_within_geometry(id, admin_level, geometry)
          FROM osm_polygon
          WHERE place_rank <= 22 AND type NOT IN ('water', 'desert', 'bay', 'reservoir')
          ORDER BY place_rank DESC;
END
$$ LANGUAGE plpgsql;
