  UPDATE osm_polygon SET geometry_center = st_centroid(geometry);
  UPDATE osm_linestring SET geometry_center = st_lineInterpolatePoint(geometry, 0.5);
  UPDATE osm_housenumber SET geometry_center = st_centroid(geometry);

  CREATE INDEX osm_linestring_geometry_center ON osm_linestring USING gist(geometry_center);
  CREATE INDEX osm_polygon_geometry_center ON osm_polygon USING gist(geometry_center);
  CREATE INDEX osm_housenumber_geometry_center ON osm_housenumber USING gist(geometry_center);
