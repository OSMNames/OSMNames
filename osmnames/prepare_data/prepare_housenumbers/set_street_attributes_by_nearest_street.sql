CREATE OR REPLACE FUNCTION nearest_street(parent_id_in BIGINT, geometry_in GEOMETRY)
RETURNS TABLE(osm_id BIGINT, name VARCHAR) AS $$
BEGIN
  RETURN QUERY
  SELECT COALESCE(street.merged_into, street.osm_id), street.name
    FROM osm_linestring AS street
    WHERE parent_id = parent_id_in
          AND st_dwithin(geometry, geometry_in, 1000)
    ORDER BY st_distance(geometry, geometry_in) ASC
    LIMIT 1;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

UPDATE osm_housenumber
  SET (street_id, street) = (SELECT * FROM nearest_street(parent_id, geometry))
WHERE street_id IS NULL
      AND parent_id IS NOT NULL;
