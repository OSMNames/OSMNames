CREATE INDEX IF NOT EXISTS idx_osm_linestring_normalized_name ON osm_linestring(normalized_name);
CREATE INDEX IF NOT EXISTS idx_osm_housenumber_parent_id ON osm_housenumber(parent_id);

-- set street ids by fully matching names
UPDATE osm_housenumber AS housenumber
  SET street_id = COALESCE(street.merged_into, street.osm_id)
FROM osm_linestring AS street
WHERE street.parent_id = housenumber.parent_id
      AND street.normalized_name = housenumber.normalized_street
      AND housenumber.street_id IS NULL
      AND housenumber.normalized_street != '';

-- set street ids for names with typos (levenshtein distance 1)
UPDATE osm_housenumber AS housenumber
  SET street_id = COALESCE(street.merged_into, street.osm_id)
FROM osm_linestring AS street
WHERE street.parent_id = housenumber.parent_id
      AND levenshtein_less_equal(street.normalized_name, housenumber.normalized_street, 1) = 1
      AND housenumber.street_id IS NULL
      AND housenumber.normalized_street != '';

-- set street ids where street name contains full street name of housenumber
-- or the housenumber street name contains the full street name of a linestring
-- e.g. Serre is fully contained in Rue de la Serre
--      and Cité Préville is fully contained in Cité Préville 19
UPDATE osm_housenumber AS housenumber
  SET street_id = COALESCE(street.merged_into, street.osm_id)
FROM osm_linestring AS street
WHERE street.parent_id = housenumber.parent_id
      AND (street.normalized_name LIKE '%' || housenumber.normalized_street || '%'
           OR housenumber.normalized_street LIKE '%' || street.normalized_name || '%')
      AND housenumber.street_id IS NULL
      AND housenumber.normalized_street != '';

DROP INDEX idx_osm_linestring_normalized_name;
