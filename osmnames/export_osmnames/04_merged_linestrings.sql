DROP MATERIALIZED VIEW IF EXISTS mv_merged_linestrings;
CREATE MATERIALIZED VIEW mv_merged_linestrings AS
SELECT getLanguageName(rrrr.name, rrrr.name_fr, rrrr.name_en, rrrr.name_de, rrrr.name_es, rrrr.name_ru, rrrr.name_zh) AS name,
    getAlternativesNames(rrrr.name, rrrr.name_fr, rrrr.name_en, rrrr.name_de, rrrr.name_es, rrrr.name_ru, rrrr.name_zh,getLanguageName(rrrr.name, rrrr.name_fr, rrrr.name_en, rrrr.name_de, rrrr.name_es, rrrr.name_ru, rrrr.name_zh),',') AS alternative_names,
    'way'::TEXT as osm_type,
    getOsmIdWithId(rrrr.member_ids[1]::BIGINT) AS osm_id,
    road_class(rrrr.type) AS class,
    rrrr.type,
    ST_X(ST_PointOnSurface(ST_Transform(rrrr.geometry, 4326))) AS lon,
    ST_Y(ST_PointOnSurface(ST_Transform(rrrr.geometry, 4326))) AS lat,
    rrrr.rank_search AS place_rank,
    getImportance(rrrr.rank_search, rrrr.wikipedia, rrrr.calculated_country_code) AS importance,
    rrrr.name AS street,
    parentInfo.city AS city,
    parentInfo.county  AS county,
    parentInfo.state  AS state,
    countryName(rrrr.partition) AS country,
    rrrr.calculated_country_code AS country_code,
    parentInfo.displayName  AS display_name,
    ST_XMIN(ST_Transform(rrrr.geometry, 4326)) AS west,
    ST_YMIN(ST_Transform(rrrr.geometry, 4326)) AS south,
    ST_XMAX(ST_Transform(rrrr.geometry, 4326)) AS east,
    ST_YMAX(ST_Transform(rrrr.geometry, 4326)) AS north,
    rrrr.wikidata AS wikidata,
    rrrr.wikipedia AS wikipedia
FROM osm_merged_multi_linestring AS rrrr , getParentInfo(getLanguageName(name, name_fr, name_en, name_de, name_es, name_ru, name_zh), parent_id, rank_search, ',') AS parentInfo
;
