DROP MATERIALIZED VIEW IF EXISTS mv_linestrings;
CREATE MATERIALIZED VIEW mv_linestrings AS
SELECT
  id,
  languageName AS name,
  alternative_names,
  'way'::TEXT as osm_type,
  osm_id::VARCHAR AS osm_id,
  determine_class(type) AS class,
  type,
  ST_X(ST_LineInterpolatePoint(ST_Transform(geometry, 4326), 0.5)) AS lon,
  ST_Y(ST_LineInterpolatePoint(ST_Transform(geometry, 4326), 0.5)) AS lat,
  rank_search AS place_rank,
  get_importance(rank_search, wikipedia, country_code) AS importance,
  name AS street,
  parentInfo.city AS city,
  parentInfo.county  AS county,
  parentInfo.state  AS state,
  country_name(country_code) AS country,
  country_code,
  parentInfo.displayName  AS display_name,
  ST_XMIN(ST_Transform(geometry, 4326)) AS west,
  ST_YMIN(ST_Transform(geometry, 4326)) AS south,
  ST_XMAX(ST_Transform(geometry, 4326)) AS east,
  ST_YMAX(ST_Transform(geometry, 4326)) AS north,
  wikidata AS wikidata,
  wikipedia AS wikipedia
FROM
  osm_linestring,
  getLanguageName(name, name_fr, name_en, name_de, name_es, name_ru, name_zh) AS languageName,
  getAlternativesNames(name, name_fr, name_en, name_de, name_es, name_ru, name_zh, languageName,',') AS alternative_names,
  getParentInfo(languageName, parent_id, rank_search, ',') AS parentInfo
