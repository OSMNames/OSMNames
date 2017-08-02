DROP MATERIALIZED VIEW IF EXISTS mv_housenumbers;
CREATE MATERIALIZED VIEW mv_housenumbers AS
SELECT
  'node'::TEXT as osm_type,
  osm_id,
  COALESCE(street_id::VARCHAR, '') AS street_id,
  COALESCE(street, '') AS street,
  housenumber,
  round(ST_X(ST_Centroid(ST_Transform(geometry, 4326)))::numeric, 7) AS lon,
  round(ST_Y(ST_Centroid(ST_Transform(geometry, 4326)))::numeric, 7) AS lat
FROM osm_housenumber
WHERE street_id IS NOT NULL;
