CREATE MATERIALIZED VIEW mv_points AS
SELECT getLanguageName(rr.name, rr.name_fr, rr.name_en, rr.name_de, rr.name_es, rr.name_ru, rr.name_zh) AS name,
    getAlternativesNames(rr.name, rr.name_fr, rr.name_en, rr.name_de, rr.name_es, rr.name_ru, rr.name_zh,getLanguageName(rr.name, rr.name_fr, rr.name_en, rr.name_de, rr.name_es, rr.name_ru, rr.name_zh),',') AS alternative_names,
    'node'::TEXT as osm_type,
    osm_id,
    city_class(rr.type) AS class,
    rr.type AS type,
    ST_X(ST_Transform(rr.geometry, 4326)) AS lon,
    ST_Y(ST_Transform(rr.geometry, 4326)) AS lat,
    rr.rank_search AS place_rank,
    getImportance(rr.rank_search, rr.wikipedia, rr.calculated_country_code) AS importance,
    ''::TEXT AS street,
    parentInfo.city AS city,
    parentInfo.county  AS county,
    parentInfo.state  AS state,
    countryName(rr.partition) AS country,
    rr.calculated_country_code AS country_code,
    parentInfo.displayName  AS display_name,  
    ST_XMIN(ST_Transform(rr.geometry, 4326)) AS west,
    ST_YMIN(ST_Transform(rr.geometry, 4326)) AS south,
    ST_XMAX(ST_Transform(rr.geometry, 4326)) AS east,
    ST_YMAX(ST_Transform(rr.geometry, 4326)) AS north,
    rr.wikidata AS wikidata,
    rr.wikipedia AS wikipedia
FROM 
    osm_point AS rr, 
    getParentInfo(getLanguageName(name, name_fr, name_en, name_de, name_es, name_ru, name_zh), parent_id, rank_search, ',') AS parentInfo 
WHERE 
    rr.linked IS FALSE
;