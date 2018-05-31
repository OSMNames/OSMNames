CREATE INDEX IF NOT EXISTS idx_osm_linestring_parent_id ON osm_linestring(parent_id);
CREATE INDEX IF NOT EXISTS osm_linestring_geom ON osm_linestring USING gist(geometry);
CREATE INDEX IF NOT EXISTS idx_osm_linestring_name ON osm_linestring(name);
CLUSTER osm_linestring_geom ON osm_linestring;

-- create merged linestrings
DROP TABLE IF EXISTS osm_merged_linestring CASCADE;
CREATE TABLE osm_merged_linestring AS
  SELECT
    min(a.id) AS id,
    array_agg(DISTINCT a.id) AS member_ids,
    min(a.osm_id) AS osm_id,
    string_agg(DISTINCT a.type,',') AS type,
    a.name,
    max(a.alternative_names) AS alternative_names,
    max(a.wikipedia) AS wikipedia,
    max(a.wikidata) AS wikidata,
    st_simplify(st_collect(a.geometry), 10) AS geometry,
    min(a.place_rank) AS place_rank,
    a.parent_id
  FROM
    osm_linestring AS a,
    osm_linestring AS b
  WHERE
    a.name = b.name AND
    a.parent_id = b.parent_id AND
    st_dwithin(a.geometry, b.geometry, 1000) AND
    a.parent_id IS NOT NULL AND
    a.id != b.id
  GROUP BY
    a.parent_id,
    a.name;

ALTER TABLE osm_merged_linestring ADD PRIMARY KEY (id);

-- drop not needed indexes
DROP INDEX idx_osm_linestring_name;
DROP INDEX osm_linestring_geom;
DROP INDEX IF EXISTS idx_osm_linestring_merged_false;

-- set merged_into for all merged linestrings
UPDATE osm_linestring SET merged_into = osm_merged_linestring.osm_id
FROM osm_merged_linestring
WHERE osm_linestring.id = ANY(osm_merged_linestring.member_ids);

CREATE INDEX idx_osm_linestring_merged_false ON osm_linestring(merged_into) WHERE merged_into IS NULL;
