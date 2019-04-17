CREATE INDEX osm_linestring_geometry_center ON osm_linestring USING gist(geometry_center); --&
CREATE INDEX osm_housenumber_geometry_center ON osm_housenumber USING gist(geometry_center); --&
