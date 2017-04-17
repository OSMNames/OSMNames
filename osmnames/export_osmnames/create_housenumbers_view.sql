DROP MATERIALIZED VIEW IF EXISTS mv_housenumbers;
CREATE MATERIALIZED VIEW mv_housenumbers AS
SELECT
  'node'::TEXT as osm_type,
  osm_id,
  COALESCE(street_id::VARCHAR, '') AS street_id,
  COALESCE(street, '') AS street,
  housenumber,
  ST_X(ST_Transform(geometry, 4326)) AS lon,
  ST_Y(ST_Transform(geometry, 4326)) AS lat
FROM osm_housenumber;
