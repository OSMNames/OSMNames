DROP MATERIALIZED VIEW IF EXISTS mv_linestrings;
CREATE MATERIALIZED VIEW mv_linestrings AS
SELECT
  id,
  name,
  alternative_names,
  'way'::TEXT as osm_type,
  osm_id::VARCHAR AS osm_id,
  class,
  type,
  ST_X(ST_LineInterpolatePoint(ST_Transform(geometry, 4326), 0.5)) AS lon,
  ST_Y(ST_LineInterpolatePoint(ST_Transform(geometry, 4326), 0.5)) AS lat,
  place_rank,
  get_importance(place_rank, wikipedia, country_code) AS importance,
  CASE WHEN class = 'highway' THEN COALESCE(name, '') ELSE '' END AS street,
  COALESCE(parentInfo.city, '') AS city,
  COALESCE(parentInfo.county, '') AS county,
  COALESCE(parentInfo.state, '') AS state,
  COALESCE(get_country_name(country_code), '') AS country,
  COALESCE(country_code, '') AS country_code,
  parentInfo.displayName  AS display_name,
  ST_XMIN(ST_Transform(geometry, 4326)) AS west,
  ST_YMIN(ST_Transform(geometry, 4326)) AS south,
  ST_XMAX(ST_Transform(geometry, 4326)) AS east,
  ST_YMAX(ST_Transform(geometry, 4326)) AS north,
  wikidata AS wikidata,
  wikipedia AS wikipedia
FROM
  osm_linestring,
  determine_class(type) AS class,
  get_parent_info(osm_linestring.name, parent_id, place_rank) AS parentInfo
WHERE merged_into IS NULL;
