DROP MATERIALIZED VIEW IF EXISTS mv_points;
CREATE MATERIALIZED VIEW mv_points AS
SELECT
  name,
  alternative_names,
  'node'::TEXT as osm_type,
  osm_id::VARCHAR AS osm_id,
  determine_class(type) AS class,
  type,
  round(ST_X(ST_Transform(geometry, 4326))::numeric, 5) AS lon,
  round(ST_Y(ST_Transform(geometry, 4326))::numeric, 5) AS lat,
  place_rank,
  get_importance(place_rank, wikipedia, parentInfo.country_code) AS importance,
  NULL::TEXT AS street,
  parentInfo.city AS city,
  parentInfo.county AS county,
  parentInfo.state AS state,
  get_country_name(parentInfo.country_code) AS country,
  parentInfo.country_code AS country_code,
  parentInfo.displayName AS display_name,
  round(ST_XMIN(ST_Transform(geometry, 4326))::numeric, 5) AS west,
  round(ST_YMIN(ST_Transform(geometry, 4326))::numeric, 5) AS south,
  round(ST_XMAX(ST_Transform(geometry, 4326))::numeric, 5) AS east,
  round(ST_YMAX(ST_Transform(geometry, 4326))::numeric, 5) AS north,
  NULLIF(wikidata, '') AS wikidata,
  NULLIF(wikipedia, '') AS wikipedia,
  NULL::VARCHAR AS housenumbers
FROM
  osm_point,
  get_parent_info(parent_id, name) as parentInfo
WHERE NOT merged;
