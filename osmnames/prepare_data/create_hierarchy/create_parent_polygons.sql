DROP TABLE IF EXISTS parent_polygons;
CREATE TABLE parent_polygons AS
  SELECT id, geometry, place_rank
  FROM osm_polygon
  WHERE place_rank <= 22
        AND (admin_level IS NOT NULL
             OR type NOT IN ('water', 'desert', 'bay', 'reservoir', 'island', 'aerodrome'))
  ORDER BY place_rank DESC;

CREATE INDEX parent_polygons_geometry ON parent_polygons USING gist(geometry);
CLUSTER parent_polygons_geometry ON parent_polygons; --&
