CREATE INDEX IF NOT EXISTS osm_linestring_normalized_name ON osm_linestring(normalized_name);
CREATE INDEX IF NOT EXISTS osm_linestring_normalized_name_trgm ON osm_linestring USING GIN(normalized_name gin_trgm_ops);

-- see https://www.postgresql.org/docs/9.6/static/pgtrgm.html for more information
UPDATE pg_settings SET setting = '0.5' WHERE name = 'pg_trgm.similarity_threshold';

DROP FUNCTION IF EXISTS best_matching_street_within_parent(BIGINT, VARCHAR);
CREATE FUNCTION best_matching_street_within_parent(parent_id_in BIGINT, name_in VARCHAR)
RETURNS BIGINT AS $$
  SELECT COALESCE(merged_into, osm_id)
    FROM osm_linestring
    WHERE parent_id = parent_id_in
          AND normalized_name % name_in
    ORDER BY similarity(normalized_name, name_in) DESC
    LIMIT 1;
$$ LANGUAGE 'sql' IMMUTABLE;

-- set street id by fully matching names within same parent
UPDATE osm_housenumber AS housenumber
  SET street_id = COALESCE(street.merged_into, street.osm_id)
FROM osm_linestring AS street
WHERE street.parent_id = housenumber.parent_id
      AND street.normalized_name = housenumber.normalized_street
      AND housenumber.street_id IS NULL
      AND housenumber.normalized_street != '';

-- set street id by best matching name within same parent
UPDATE osm_housenumber
  SET street_id = best_matching_street_within_parent(parent_id, normalized_street)
  WHERE street_id IS NULL
        AND normalized_street <> ''
        AND parent_id IS NOT NULL;

DROP INDEX osm_linestring_normalized_name;
DROP INDEX osm_linestring_normalized_name_trgm;
