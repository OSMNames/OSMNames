CREATE INDEX IF NOT EXISTS idx_osm_housenumber_normalized_street ON osm_housenumber(normalized_street);
CREATE INDEX IF NOT EXISTS idx_osm_linestring_normalized_name ON osm_linestring(normalized_name);
CREATE INDEX IF NOT EXISTS idx_osm_housenumber_parent_id ON osm_housenumber(parent_id);

UPDATE osm_housenumber AS housenumber
  SET street_id = COALESCE(street.merged_into, street.osm_id)
FROM osm_linestring AS street
WHERE street.parent_id = housenumber.parent_id
      AND street.normalized_name = housenumber.normalized_street
      AND housenumber.street_id IS NULL;

DROP INDEX idx_osm_housenumber_normalized_street;
DROP INDEX idx_osm_linestring_normalized_name;
