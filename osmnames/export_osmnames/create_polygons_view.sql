DROP MATERIALIZED VIEW IF EXISTS mv_polygons;
CREATE MATERIALIZED VIEW mv_polygons AS
SELECT
  id,
  relation_name AS name,
  alternative_names,
  CASE WHEN osm_id > 0 THEN 'way' ELSE 'relation' END AS osm_type,
  abs(osm_id)::VARCHAR as osm_id,
  determine_class(relation_type) AS class,
  relation_type,
  ST_X(ST_PointOnSurface(ST_Buffer(ST_Transform(geometry, 4326), 0.0))) AS lon,
  ST_Y(ST_PointOnSurface(ST_Buffer(ST_Transform(geometry, 4326), 0.0))) AS lat,
  place_rank,
  get_importance(place_rank, wikipedia, country_code) AS importance,
  ''::TEXT AS street,
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
  osm_polygon,
  get_parent_info(name, id, parent_id, True, type) as parentInfo,
  get_type_for_relations(linked_osm_id, type, place_rank) AS relation_type,
  COALESCE(NULLIF(get_name_for_relations(linked_osm_id, relation_type), ''), osm_polygon.name) AS relation_name;
