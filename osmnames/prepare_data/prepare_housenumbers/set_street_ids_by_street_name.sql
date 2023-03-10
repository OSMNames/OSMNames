CREATE INDEX IF NOT EXISTS osm_linestring_normalized_name ON osm_linestring(normalized_name); --&
CREATE INDEX IF NOT EXISTS osm_linestring_normalized_name_trgm ON osm_linestring USING GIN(normalized_name gin_trgm_ops); --&
CREATE INDEX IF NOT EXISTS osm_linestring_geometry ON osm_linestring USING GIST(geometry); --&
CREATE INDEX IF NOT EXISTS osm_housenumber_normalized_street ON osm_housenumber(normalized_street); --&
CREATE INDEX IF NOT EXISTS osm_housenumber_geometry_center ON osm_housenumber USING GIST(geometry_center); --&

-- see https://www.postgresql.org/docs/9.6/static/pgtrgm.html for more information
UPDATE pg_settings SET setting = '0.5' WHERE name = 'pg_trgm.similarity_threshold';

DROP FUNCTION IF EXISTS best_matching_street_within_parent(BIGINT, GEOMETRY, VARCHAR);
CREATE FUNCTION best_matching_street_within_parent(parent_id_in BIGINT, geometry_in GEOMETRY, name_in VARCHAR)
RETURNS BIGINT AS $$
  SELECT COALESCE(merged_into, osm_id)
    FROM osm_linestring
    WHERE parent_id = parent_id_in
          AND st_dwithin(geometry_in, geometry, 1000) -- added due better performance
          AND normalized_name % name_in
    ORDER BY similarity(normalized_name, name_in) DESC
    LIMIT 1;
$$ LANGUAGE 'sql' IMMUTABLE;

DROP FUNCTION IF EXISTS best_matching_street_within_range(GEOMETRY, VARCHAR);
CREATE FUNCTION best_matching_street_within_range(geometry_in GEOMETRY, name_in VARCHAR)
RETURNS BIGINT AS $$
  SELECT COALESCE(merged_into, osm_id)
    FROM osm_linestring
    WHERE st_dwithin(geometry_in, geometry, 1000)
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

-- set street id by fully matching names within range
UPDATE osm_housenumber AS housenumber
  SET street_id = COALESCE(street.merged_into, street.osm_id)
FROM osm_linestring AS street
WHERE st_dwithin(street.geometry, housenumber.geometry_center, 1000)
      AND street.normalized_name = housenumber.normalized_street
      AND housenumber.street_id IS NULL
      AND housenumber.normalized_street != '';

-- set street id by best matching name within same parent
UPDATE osm_housenumber
  SET street_id = best_matching_street_within_parent(parent_id, geometry_center, normalized_street)
  WHERE street_id IS NULL
        AND normalized_street <> ''
        AND parent_id IS NOT NULL;


-- This step is commented since it is to expensive to execute for a large amount of house numbers.
-- Consider executing this step when less house numbers without street left (e.g. after Issue #109)
--
-- set street id by best matching name within range
-- UPDATE osm_housenumber
--   SET street_id = best_matching_street_within_range(geometry_center, normalized_street)
--   WHERE street_id IS NULL
--         AND normalized_street <> ''
--         AND parent_id IS NOT NULL;

DROP INDEX osm_linestring_normalized_name; --&
DROP INDEX osm_linestring_normalized_name_trgm; --&
DROP INDEX osm_housenumber_normalized_street; --&
DROP INDEX osm_housenumber_geometry_center; --&
