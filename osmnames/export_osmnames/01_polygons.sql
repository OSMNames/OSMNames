DROP MATERIALIZED VIEW IF EXISTS mv_polygons;
CREATE MATERIALIZED VIEW mv_polygons AS
SELECT
  id,
  relationName AS name,
  alternative_names,
  CASE WHEN osm_id > 0 THEN 'way' ELSE 'relation' END AS osm_type,
  abs(osm_id)::VARCHAR as osm_id,
  determine_class(getTypeForRelations(linked_osm_id, type, rank_search)) AS class,
  getTypeForRelations(linked_osm_id, type, rank_search) AS type,
  ST_X(ST_PointOnSurface(ST_Buffer(ST_Transform(geometry, 4326), 0.0))) AS lon,
  ST_Y(ST_PointOnSurface(ST_Buffer(ST_Transform(geometry, 4326), 0.0))) AS lat,
  rank_search AS place_rank,
  get_importance(rank_search, wikipedia, country_code) AS importance,
  ''::TEXT AS street,
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
  osm_polygon,
  getLanguageName(name, name_fr, name_en, name_de, name_es, name_ru, name_zh) AS languageName,
  getParentInfo(languageName, parent_id, rank_search, ',') AS parentInfo,
  COALESCE(NULLIF(getNameForRelations(linked_osm_id, getTypeForRelations(linked_osm_id, type, rank_search)), ''), languageName) AS relationName,
  getAlternativesNames(name, name_fr, name_en, name_de, name_es, name_ru, name_zh, relationName, ',') AS alternative_names
;
