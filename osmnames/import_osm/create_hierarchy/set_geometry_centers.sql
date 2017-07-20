  UPDATE osm_polygon SET geometry_center = st_centroid(geometry);
  UPDATE osm_linestring SET geometry_center = st_lineInterpolatePoint(geometry, 0.5);

  CREATE INDEX osm_linestring_center_geom ON osm_linestring USING gist(geometry_center);
  CREATE INDEX osm_polygon_center_geom ON osm_polygon USING gist(geometry_center);
