DROP MATERIALIZED VIEW IF EXISTS mv_merged_linestrings;
CREATE MATERIALIZED VIEW mv_merged_linestrings AS
SELECT
  name,
  alternative_names,
  'way'::TEXT as osm_type,
  osm_id::VARCHAR AS osm_id,
  class,
  type,
  ST_X(ST_PointOnSurface(ST_Transform(geometry, 4326))) AS lon,
  ST_Y(ST_PointOnSurface(ST_Transform(geometry, 4326))) AS lat,
  place_rank,
  get_importance(place_rank, wikipedia, parentInfo.country_code) AS importance,
  CASE WHEN class = 'highway' THEN COALESCE(name, '') ELSE '' END AS street,
  COALESCE(parentInfo.city, '') AS city,
  COALESCE(parentInfo.county, '') AS county,
  COALESCE(parentInfo.state, '') AS state,
  COALESCE(get_country_name(parentInfo.country_code), '') AS country,
  COALESCE(parentInfo.country_code, '') AS country_code,
  parentInfo.displayName AS display_name,
  ST_XMIN(ST_Transform(geometry, 4326)) AS west,
  ST_YMIN(ST_Transform(geometry, 4326)) AS south,
  ST_XMAX(ST_Transform(geometry, 4326)) AS east,
  ST_YMAX(ST_Transform(geometry, 4326)) AS north,
  wikidata AS wikidata,
  wikipedia AS wikipedia
FROM
  osm_merged_multi_linestring,
  determine_class(type) AS class,
  get_parent_info(parent_id, name) as parentInfo;
