CLUSTER osm_polygon USING idx_osm_polgyon_geom;
CLUSTER osm_point USING idx_osm_point_geom;
CLUSTER osm_linestring USING idx_osm_linestring_geom;
CLUSTER osm_housenumber USING idx_osm_housenumber_geom;

VACUUM ANALYZE osm_polygon;
VACUUM ANALYZE osm_point;
VACUUM ANALYZE osm_linestring;
VACUUM ANALYZE osm_housenumber;

DO $$
BEGIN
  FOR current_rank IN REVERSE 22..4 LOOP
    PERFORM set_parent_id_for_containing_entities(id, admin_level, geometry) FROM osm_polygon WHERE place_rank = current_rank;
  END LOOP;
END
$$ LANGUAGE plpgsql;
