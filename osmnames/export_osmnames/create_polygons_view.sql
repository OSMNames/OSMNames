DROP MATERIALIZED VIEW IF EXISTS mv_polygons;
CREATE MATERIALIZED VIEW mv_polygons AS
SELECT
  name,
  alternative_names,
  CASE WHEN osm_id > 0 THEN 'way' ELSE 'relation' END AS osm_type,
  abs(osm_id)::VARCHAR as osm_id,
  determine_class(type) AS class,
  type,
  round(ST_X(ST_PointOnSurface(ST_Buffer(ST_Transform(geometry, 4326), 0.0)))::numeric::numeric, 7) AS lon,
  round(ST_Y(ST_PointOnSurface(ST_Buffer(ST_Transform(geometry, 4326), 0.0)))::numeric::numeric, 7) AS lat,
  place_rank,
  get_importance(place_rank, wikipedia, parentInfo.country_code) AS importance,
  ''::TEXT AS street,
  COALESCE(parentInfo.city, '') AS city,
  COALESCE(parentInfo.county, '') AS county,
  COALESCE(parentInfo.state, '') AS state,
  COALESCE(get_country_name(parentInfo.country_code), '') AS country,
  COALESCE(parentInfo.country_code, '') AS country_code,
  parentInfo.displayName  AS display_name,
  round(bounding_box[1]::numeric, 7) AS west,
  round(bounding_box[2]::numeric, 7) AS south,
  round(bounding_box[3]::numeric, 7) AS east,
  round(bounding_box[4]::numeric, 7) AS north,
  wikidata AS wikidata,
  wikipedia AS wikipedia,
  ''::VARCHAR AS housenumbers
FROM
  osm_polygon,
  get_parent_info(id, '') as parentInfo,
  get_bounding_box(geometry, parentInfo.country_code, admin_level) AS bounding_box;
