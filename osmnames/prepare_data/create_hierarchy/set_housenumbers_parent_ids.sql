CREATE OR REPLACE FUNCTION set_parent_id_for_housenumbers_within_geometry(id_in BIGINT, geometry_in GEOMETRY)
RETURNS VOID AS $$
BEGIN
  UPDATE osm_housenumber SET parent_id = id_in WHERE parent_id IS NULL
                                                     AND geometry_in && geometry_center
                                                     AND st_contains(geometry_in, geometry_center);
END;
$$ LANGUAGE plpgsql;

SELECT set_parent_id_for_housenumbers_within_geometry(id, geometry)
       FROM parent_polygons ORDER BY place_rank DESC, admin_level DESC;
