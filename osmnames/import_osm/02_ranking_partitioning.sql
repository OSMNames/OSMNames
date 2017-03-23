DROP TABLE IF EXISTS osm_polygon CASCADE;
CREATE TABLE osm_polygon AS
(SELECT
    id,
    osm_id,
    type,
    country_code,
    name,
    name_fr,
    name_en,
    name_de,
    name_es,
    name_ru,
    name_zh,
    wikipedia,
    wikidata,
    admin_level,
    geometry,
    rpc.rank_search AS rank_search,
    rpc.partition AS partition,
    rpc.calculated_country_code AS calculated_country_code,
    NULL::bigint AS parent_id,
    NULL::bigint AS linked_osm_id
FROM
    osm_polygon_tmp p,
    determineRankPartitionCode(type, geometry, osm_id, country_code) AS rpc
);
ALTER TABLE osm_polygon ADD PRIMARY KEY (id);


DROP TABLE IF EXISTS osm_point CASCADE;
CREATE TABLE osm_point AS
(SELECT
    id,
    osm_id,
    type,
    name,
    name_fr,
    name_en,
    name_de,
    name_es,
    name_ru,
    name_zh,
    wikipedia,
    wikidata,
    admin_level,
    geometry,
    rpc.rank_search AS rank_search,
    rpc.partition AS partition,
    rpc.calculated_country_code AS calculated_country_code,
    NULL::bigint AS parent_id,
    FALSE::boolean AS linked
FROM
    osm_point_tmp,
    determineRankPartitionCode(type, geometry, osm_id, NULL) AS rpc
);
DROP TABLE osm_point_tmp;
DROP TABLE osm_polygon_tmp;
ALTER TABLE osm_point ADD PRIMARY KEY (id);


DROP TABLE IF EXISTS osm_linestring CASCADE;
CREATE TABLE osm_linestring AS
(SELECT
    id,
    osm_id,
    type,
    name,
    name_fr,
    name_en,
    name_de,
    name_es,
    name_ru,
    name_zh,
    wikipedia,
    wikidata,
    admin_level,
    geometry,
    rpc.rank_search AS rank_search,
    rpc.partition AS partition,
    rpc.calculated_country_code AS calculated_country_code,
    NULL::bigint AS parent_id,
    FALSE::boolean AS merged
FROM
    osm_linestring_tmp,
    determineRankPartitionCode(type, geometry, NULL, NULL) AS rpc
);
DROP TABLE osm_linestring_tmp;
ALTER TABLE osm_linestring ADD PRIMARY KEY (id);


--create indexes
CREATE INDEX IF NOT EXISTS idx_osm_polgyon_geom ON osm_polygon USING gist (geometry);
CREATE INDEX IF NOT EXISTS idx_osm_point_geom ON osm_point USING gist (geometry);
CREATE INDEX IF NOT EXISTS idx_osm_linestring_geom ON osm_linestring USING gist (geometry);

CREATE INDEX IF NOT EXISTS idx_osm_polygon_partition_rank ON osm_polygon (partition,rank_search);
CREATE INDEX IF NOT EXISTS idx_osm_polygon_id ON osm_polygon (id);

CREATE INDEX IF NOT EXISTS idx_osm_point_osm_id ON osm_point (osm_id);

CREATE INDEX IF NOT EXISTS idx_osm_linestring_id ON osm_linestring (id);

--delete entries with faulty geometries from import
DELETE FROM osm_polygon WHERE ST_IsEmpty(geometry);

--determine missed partition and country codes from import dataset
UPDATE osm_polygon SET partition = determinePartitionFromImportedData(geometry)
WHERE partition = 0;

UPDATE osm_polygon SET calculated_country_code = c.country_code
FROM country_name c
WHERE calculated_country_code IS NULL AND osm_polygon.partition = c.partition;

UPDATE osm_point SET partition = determinePartitionFromImportedData(geometry)
WHERE partition = 0;

UPDATE osm_point SET calculated_country_code = c.country_code
FROM country_name c
WHERE calculated_country_code IS NULL AND osm_point.partition = c.partition;

UPDATE osm_linestring SET partition = determinePartitionFromImportedData(geometry)
WHERE partition = 0;

UPDATE osm_linestring SET calculated_country_code = c.country_code
FROM country_name c
WHERE calculated_country_code IS NULL AND osm_linestring.partition = c.partition;
