DROP MATERIALIZED VIEW IF EXISTS mv_linestrings;
CREATE MATERIALIZED VIEW mv_linestrings AS
SELECT getLanguageName(rrr.name, rrr.name_fr, rrr.name_en, rrr.name_de, rrr.name_es, rrr.name_ru, rrr.name_zh) AS name,
    getAlternativesNames(rrr.name, rrr.name_fr, rrr.name_en, rrr.name_de, rrr.name_es, rrr.name_ru, rrr.name_zh,getLanguageName(rrr.name, rrr.name_fr, rrr.name_en, rrr.name_de, rrr.name_es, rrr.name_ru, rrr.name_zh),',') AS alternative_names,
    'way'::TEXT as osm_type,
    osm_id,
    road_class(rrr.type) AS class,
    rrr.type,
    ST_X(ST_LineInterpolatePoint(ST_Transform(rrr.geometry, 4326), 0.5)) AS lon,
    ST_Y(ST_LineInterpolatePoint(ST_Transform(rrr.geometry, 4326), 0.5)) AS lat,
    rrr.rank_search AS place_rank,
    getImportance(rrr.rank_search, rrr.wikipedia, rrr.calculated_country_code) AS importance,
    rrr.name AS street,
    parentInfo.city AS city,
    parentInfo.county  AS county,
    parentInfo.state  AS state,
    countryName(rrr.partition) AS country,
    rrr.calculated_country_code AS country_code,
    parentInfo.displayName  AS display_name,
    ST_XMIN(ST_Transform(rrr.geometry, 4326)) AS west,
    ST_YMIN(ST_Transform(rrr.geometry, 4326)) AS south,
    ST_XMAX(ST_Transform(rrr.geometry, 4326)) AS east,
    ST_YMAX(ST_Transform(rrr.geometry, 4326)) AS north,
    rrr.wikidata AS wikidata,
    rrr.wikipedia AS wikipedia
FROM osm_linestring AS rrr,  getParentInfo(getLanguageName(name, name_fr, name_en, name_de, name_es, name_ru, name_zh), parent_id, rank_search, ',') AS parentInfo WHERE merged IS FALSE
;
