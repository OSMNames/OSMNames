CREATE INDEX IF NOT EXISTS idx_osm_housenumber_street ON osm_housenumber(street);
CREATE INDEX IF NOT EXISTS idx_osm_linestring_name ON osm_linestring(name);

UPDATE osm_housenumber AS housenumber
  SET street_id = COALESCE(street.merged_into, street.osm_id)
FROM osm_linestring AS street
WHERE (street.parent_id = housenumber.parent_id OR housenumber.parent_id = ANY(street.intersecting_polygon_ids))
      AND street.name = housenumber.street
      AND housenumber.street_id IS NULL;

DROP INDEX idx_osm_housenumber_street;
DROP INDEX idx_osm_linestring_name;
