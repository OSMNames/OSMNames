DROP MATERIALIZED VIEW IF EXISTS mv_points;
CREATE MATERIALIZED VIEW mv_points AS
SELECT
  id,
  languageName AS name,
  alternative_names,
  'node'::TEXT as osm_type,
  osm_id::VARCHAR AS osm_id,
  determine_class(type) AS class,
  type,
  ST_X(ST_Transform(geometry, 4326)) AS lon,
  ST_Y(ST_Transform(geometry, 4326)) AS lat,
  place_rank AS place_rank,
  get_importance(place_rank, wikipedia, country_code) AS importance,
  ''::TEXT AS street,
  COALESCE(parentInfo.city, '') AS city,
  COALESCE(parentInfo.county, '') AS county,
  COALESCE(parentInfo.state, '') AS state,
  COALESCE(country_name(country_code), '') AS country,
  COALESCE(country_code, '') AS country_code,
  parentInfo.displayName  AS display_name,
  ST_XMIN(ST_Transform(geometry, 4326)) AS west,
  ST_YMIN(ST_Transform(geometry, 4326)) AS south,
  ST_XMAX(ST_Transform(geometry, 4326)) AS east,
  ST_YMAX(ST_Transform(geometry, 4326)) AS north,
  wikidata,
  wikipedia
FROM
  osm_point,
  getLanguageName(name, name_fr, name_en, name_de, name_es, name_ru, name_zh) AS languageName,
  get_parent_info(languageName, parent_id, place_rank) AS parentInfo,
  get_alternative_names(all_tags, name, ',') AS alternative_names
WHERE
  linked IS FALSE;
