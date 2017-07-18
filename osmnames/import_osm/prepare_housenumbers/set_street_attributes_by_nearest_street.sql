DROP FUNCTION IF EXISTS nearest_street(BIGINT, geometry);
CREATE FUNCTION nearest_street(parent_id_in BIGINT, geometry_in GEOMETRY)
RETURNS TABLE(osm_id BIGINT, name VARCHAR) AS $$
BEGIN
  RETURN QUERY
  SELECT COALESCE(street.merged_into, street.osm_id), street.name
    FROM osm_linestring AS street
    WHERE parent_id = parent_id_in
    ORDER BY st_distance(geometry, geometry_in) ASC
    LIMIT 1;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

CREATE INDEX idx_osm_linestring_parent_id ON osm_linestring(parent_id);

UPDATE osm_housenumber
  SET (street_id, street) = (SELECT * FROM nearest_street(parent_id, geometry))
WHERE street_id IS NULL
      AND street = '' IS NOT FALSE
      AND parent_id IS NOT NULL;
