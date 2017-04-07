CLUSTER osm_polygon USING idx_osm_polgyon_geom;
CLUSTER osm_point USING idx_osm_point_geom;
CLUSTER osm_linestring USING idx_osm_linestring_geom;


VACUUM ANALYZE osm_polygon;
VACUUM ANALYZE osm_point;
VACUUM ANALYZE osm_linestring;

--determine parents
UPDATE osm_polygon SET parent_id = determine_parent_id(id, rank_search, geometry);
UPDATE osm_point SET parent_id = determine_parent_id(id, rank_search, geometry) WHERE linked IS FALSE;
UPDATE osm_housenumber SET parent_id = determine_parent_id(id, 25, geometry);
SELECT determineRoadHierarchyForEachCountry();


VACUUM ANALYZE osm_linestring;