DROP FUNCTION IF EXISTS set_parent_id_for_polygons_within_geometry(BIGINT, INT, geometry);
CREATE FUNCTION set_parent_id_for_polygons_within_geometry(id_in BIGINT, place_rank_in INT, geometry_in GEOMETRY)
RETURNS VOID AS $$
BEGIN
  UPDATE osm_polygon SET parent_id = id_in WHERE parent_id IS NULL
                                                 AND id_in != id
                                                 AND geometry_in && geometry
                                                 AND st_contains(geometry_in, geometry)
                                                 AND COALESCE(place_rank, 100) > COALESCE(place_rank_in, -1);
END;
$$ LANGUAGE plpgsql;

SELECT set_parent_id_for_polygons_within_geometry(id, place_rank, geometry)
       FROM parent_polygons ORDER BY place_rank DESC, admin_level DESC;
