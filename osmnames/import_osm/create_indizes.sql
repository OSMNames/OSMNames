CREATE INDEX IF NOT EXISTS idx_osm_polgyon_geom ON osm_polygon USING gist (geometry);
CREATE INDEX IF NOT EXISTS idx_osm_point_geom ON osm_point USING gist (geometry);
CREATE INDEX IF NOT EXISTS idx_osm_linestring_geom ON osm_linestring USING gist (geometry);
CREATE INDEX IF NOT EXISTS idx_osm_housenumber_geom ON osm_housenumber USING gist (geometry);

CLUSTER osm_polygon USING idx_osm_polgyon_geom;
CLUSTER osm_point USING idx_osm_point_geom;
CLUSTER osm_linestring USING idx_osm_linestring_geom;
CLUSTER osm_housenumber USING idx_osm_housenumber_geom;
