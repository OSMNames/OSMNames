DROP MATERIALIZED VIEW IF EXISTS mv_polygons;
CREATE MATERIALIZED VIEW mv_polygons AS
SELECT
  id,
  relationName AS name,
  alternative_names,
  CASE WHEN osm_id > 0 THEN 'way' ELSE 'relation' END AS osm_type,
  abs(osm_id)::VARCHAR as osm_id,
  determine_class(getTypeForRelations(linked_osm_id, type, place_rank)) AS class,
  getTypeForRelations(linked_osm_id, type, place_rank) AS type,
  ST_X(ST_PointOnSurface(ST_Buffer(ST_Transform(geometry, 4326), 0.0))) AS lon,
  ST_Y(ST_PointOnSurface(ST_Buffer(ST_Transform(geometry, 4326), 0.0))) AS lat,
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
  wikidata AS wikidata,
  wikipedia AS wikipedia
FROM
  osm_polygon,
  getLanguageName(name, name_fr, name_en, name_de, name_es, name_ru, name_zh) AS languageName,
  get_parent_info(languageName, parent_id, place_rank) AS parentInfo,
  COALESCE(NULLIF(getNameForRelations(linked_osm_id, getTypeForRelations(linked_osm_id, type, place_rank)), ''), languageName) AS relationName,
  getAlternativesNames(name, name_fr, name_en, name_de, name_es, name_ru, name_zh, relationName, ',') AS alternative_names
;
