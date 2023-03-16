UPDATE osm_linestring SET geometry_center = st_lineInterpolatePoint(geometry, 0.5) WHERE auto_modulo(id); --&
UPDATE osm_housenumber SET geometry_center = st_centroid(geometry) WHERE auto_modulo(id); --&
