CLUSTER osm_polygon USING idx_osm_polgyon_geom;
CLUSTER osm_point USING idx_osm_point_geom;
CLUSTER osm_linestring USING idx_osm_linestring_geom;
CLUSTER osm_housenumber USING idx_osm_housenumber_geom;

VACUUM ANALYZE osm_polygon;
VACUUM ANALYZE osm_point;
VACUUM ANALYZE osm_linestring;
VACUUM ANALYZE osm_housenumber;

SELECT determine_parent_ids();
