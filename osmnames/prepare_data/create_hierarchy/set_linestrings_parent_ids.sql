DROP FUNCTION IF EXISTS set_parent_id_for_linestrings_within_geometry(BIGINT, INT, geometry);
CREATE FUNCTION set_parent_id_for_linestrings_within_geometry(id_in BIGINT, place_rank_in INT, geometry_in GEOMETRY)
RETURNS VOID AS $$
BEGIN
  UPDATE osm_linestring SET parent_id = id_in WHERE parent_id IS NULL
                                                    AND id_in != id
                                                    AND geometry_in && geometry_center
                                                    AND st_contains(geometry_in, geometry_center);
END;
$$ LANGUAGE plpgsql;

SELECT set_parent_id_for_linestrings_within_geometry(id, place_rank, geometry)
       FROM parent_polygons;