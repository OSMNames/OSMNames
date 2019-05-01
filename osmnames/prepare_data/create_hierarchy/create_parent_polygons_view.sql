DROP MATERIALIZED VIEW IF EXISTS parent_polygons;
CREATE MATERIALIZED VIEW parent_polygons AS
  SELECT id, geometry, place_rank
  FROM osm_polygon
  WHERE place_rank <= 22
        AND (admin_level IS NOT NULL
             OR type NOT IN ('water', 'desert', 'bay', 'reservoir', 'island', 'aerodrome'))
  ORDER BY place_rank DESC;
