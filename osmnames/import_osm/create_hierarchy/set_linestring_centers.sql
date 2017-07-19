  UPDATE osm_linestring SET geometry_center = st_line_interpolate_point(geometry, 0.5);

  CREATE INDEX osm_linestring_center_geom ON osm_linestring USING gist(geometry_center)
