DROP FUNCTION IF EXISTS get_most_intersecting_polygon_id_for_polygon(BIGINT, geometry, INT);
CREATE FUNCTION get_most_intersecting_polygon_id_for_polygon(id_in BIGINT, geometry_in GEOMETRY, admin_level_in INT)
RETURNS BIGINT AS $$
DECLARE
  parent_id BIGINT;
BEGIN
  SELECT id FROM osm_polygon WHERE id != id_in
                                   AND st_intersects(geometry, geometry_in)
                                   AND st_area(geometry) > st_area(geometry_in)
                                   AND COALESCE(admin_level, 100) < COALESCE(admin_level_in, -1)
                                   AND type NOT IN ('water', 'desert', 'bay', 'reservoir')
                                   ORDER BY place_rank DESC,
                                            st_area(st_intersection(geometry, geometry_in)) DESC
                                   LIMIT 1
                                   INTO parent_id;
  RETURN parent_id;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

UPDATE osm_polygon
  SET parent_id = get_most_intersecting_polygon_id_for_polygon(id, geometry, admin_level)
WHERE parent_id IS NULL;
