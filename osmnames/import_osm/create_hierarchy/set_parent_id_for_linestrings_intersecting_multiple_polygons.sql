DROP FUNCTION IF EXISTS get_intersecting_polygon_ids_for_linestring(geometry);
CREATE FUNCTION get_intersecting_polygon_ids_for_linestring(geometry_in GEOMETRY)
RETURNS TABLE(parent_id_r BIGINT, intersecting_polygon_ids_r BIGINT[]) AS $$
DECLARE
  intersecting_polygon_ids BIGINT[];
BEGIN
  intersecting_polygon_ids := array(
    SELECT id FROM osm_polygon WHERE st_intersects(geometry, geometry_in)
                                     AND parent_id IS NOT NULL
                                     AND place_rank >= 16 AND place_rank <= 22
                                     AND type NOT IN ('water', 'desert', 'bay', 'reservoir')
                                     ORDER BY place_rank DESC,
                                              admin_level DESC,
                                              st_length(st_intersection(geometry, geometry_in)) DESC
                                            );

  RETURN QUERY SELECT intersecting_polygon_ids[1], intersecting_polygon_ids;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

UPDATE osm_linestring
  SET (parent_id, intersecting_polygon_ids) = (SELECT * FROM get_intersecting_polygon_ids_for_linestring(geometry))
WHERE parent_id IS NULL;
