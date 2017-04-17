CLUSTER osm_polygon USING idx_osm_polgyon_geom;
CLUSTER osm_point USING idx_osm_point_geom;
CLUSTER osm_linestring USING idx_osm_linestring_geom;
CLUSTER osm_housenumber USING idx_osm_housenumber_geom;

VACUUM ANALYZE osm_polygon;
VACUUM ANALYZE osm_point;
VACUUM ANALYZE osm_linestring;
VACUUM ANALYZE osm_housenumber;


DROP FUNCTION IF EXISTS set_parent_id_for_containing_entities(BIGINT, INT, geometry);
CREATE FUNCTION set_parent_id_for_containing_entities(id_in BIGINT, admin_level_in INT, geometry_value GEOMETRY) RETURNS VOID AS $$
BEGIN
  UPDATE osm_linestring SET parent_id = id_in WHERE parent_id IS NULL
                                                    AND id_in != id
                                                    AND ST_Contains(geometry_value, geometry);

  UPDATE osm_polygon SET parent_id = id_in WHERE parent_id IS NULL
                                                 AND id_in != id
                                                 AND admin_level > admin_level_in
                                                 AND ST_Contains(geometry_value, geometry);

  UPDATE osm_housenumber SET parent_id = id_in WHERE parent_id IS NULL
                                                     AND id_in != id
                                                     AND ST_Contains(geometry_value, geometry);

  UPDATE osm_point SET parent_id = id_in WHERE parent_id IS NULL
                                               AND id_in != id
                                               AND ST_Contains(geometry_value, geometry);
END;


$$ LANGUAGE plpgsql;
DO $$
BEGIN
  FOR current_rank IN REVERSE 22..4 LOOP
    PERFORM set_parent_id_for_containing_entities(id, admin_level, geometry) FROM osm_polygon WHERE place_rank = current_rank;
  END LOOP;
END
$$ LANGUAGE plpgsql;
