UPDATE osm_point AS point
SET parent_id = (
  SELECT id FROM parent_polygons AS polygon
  WHERE ST_Contains(polygon.geometry, point.geometry)
  AND polygon.place_rank < point.place_rank
  ORDER BY place_rank DESC
  LIMIT 1
);
