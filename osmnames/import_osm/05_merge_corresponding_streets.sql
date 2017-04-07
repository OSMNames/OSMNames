-- create merged linestrings
DROP TABLE IF EXISTS osm_merged_multi_linestring CASCADE;
CREATE TABLE osm_merged_multi_linestring AS
  SELECT
    min(a.id) AS id,
    array_agg(DISTINCT a.id) AS member_ids,
    min(a.osm_id) AS osm_id,
    string_agg(DISTINCT a.type,',') AS type,
    a.name,
    max(a.name_fr) AS name_fr,
    max(a.name_en) AS name_en,
    max(a.name_de) AS name_de,
    max(a.name_es) AS name_es,
    max(a.name_ru) AS name_ru,
    max(a.name_zh) AS name_zh,
    max(a.wikipedia) AS wikipedia,
    max(a.wikidata) AS wikidata,
    ST_UNION(array_agg(a.geometry)) AS geometry,
    max(a.country_code) AS country_code,
    min(a.rank_search) AS rank_search,
    a.parent_id
  FROM
    osm_linestring AS a,
    osm_linestring AS b
  WHERE
    ST_Touches(a.geometry, b.geometry) AND
    a.parent_id = b.parent_id AND
    a.parent_id IS  NOT NULL AND
    a.name = b.name AND
    a.id!=b.id
  GROUP BY
    a.parent_id,
    a.name;

ALTER TABLE osm_merged_multi_linestring ADD PRIMARY KEY (id);


UPDATE osm_linestring SET merged = TRUE WHERE id IN
  (SELECT  unnest(member_ids) FROM osm_merged_multi_linestring);

--create index
CREATE INDEX IF NOT EXISTS idx_osm_linestring_merged_false ON osm_linestring (merged) WHERE merged IS FALSE;



