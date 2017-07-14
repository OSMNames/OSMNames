DROP FUNCTION IF EXISTS get_intersecting_polygon_ids_for_linestring(geometry);
CREATE FUNCTION get_intersecting_polygon_ids_for_linestring(geometry_in GEOMETRY)
RETURNS BIGINT[] AS $$
BEGIN
  RETURN array(
    SELECT id FROM osm_polygon WHERE st_intersects(geometry, geometry_in)
                                     AND parent_id IS NOT NULL
                                     AND place_rank >= 16 AND place_rank <= 22
                                     AND type NOT IN ('water', 'desert', 'bay', 'reservoir')
                                     ORDER BY place_rank DESC,
                                              admin_level DESC,
                                              st_length(st_intersection(geometry, geometry_in)) DESC
  );
END;
$$ LANGUAGE plpgsql IMMUTABLE;

UPDATE osm_linestring
  SET parent_id = (get_intersecting_polygon_ids_for_linestring(geometry))[1],
      intersecting_polygon_ids = get_intersecting_polygon_ids_for_linestring(geometry)
WHERE parent_id IS NULL;
