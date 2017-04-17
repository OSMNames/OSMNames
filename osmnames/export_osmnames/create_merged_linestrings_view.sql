DROP MATERIALIZED VIEW IF EXISTS mv_merged_linestrings;
CREATE MATERIALIZED VIEW mv_merged_linestrings AS
SELECT
  id,
  languageName AS name,
  alternative_names,
  'way'::TEXT as osm_type,
  osm_id::VARCHAR AS osm_id,
  determine_class(type) AS class,
  type,
  ST_X(ST_PointOnSurface(ST_Transform(geometry, 4326))) AS lon,
  ST_Y(ST_PointOnSurface(ST_Transform(geometry, 4326))) AS lat,
  place_rank AS place_rank,
  get_importance(place_rank, wikipedia, country_code) AS importance,
  COALESCE(name, '') AS street,
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
  wikidata AS wikidata,
  wikipedia AS wikipedia
FROM
  osm_merged_multi_linestring,
  getLanguageName(name, name_fr, name_en, name_de, name_es, name_ru, name_zh) AS languageName,
  get_parent_info(languageName, parent_id, place_rank) AS parentInfo,
  getAlternativesNames(name, name_fr, name_en, name_de, name_es, name_ru, name_zh, languageName, ',') AS alternative_names
;
