DROP FUNCTION IF EXISTS set_country_code_for_elements_within_geometry(VARCHAR(2), geometry);
CREATE FUNCTION set_country_code_for_elements_within_geometry(country_code_in VARCHAR(2), geometry_value GEOMETRY) RETURNS VOID AS $$
BEGIN
  UPDATE osm_linestring SET country_code = country_code_in WHERE country_code = '' IS NOT FALSE
                                                                 AND st_contains(geometry_value, geometry);

  UPDATE osm_point SET country_code = country_code_in WHERE country_code = '' IS NOT FALSE
                                                            AND st_contains(geometry_value, geometry);

  UPDATE osm_polygon SET country_code = country_code_in WHERE country_code = '' IS NOT FALSE
                                                              AND st_contains(geometry_value, geometry);

  UPDATE osm_housenumber SET country_code = country_code_in WHERE country_code = '' IS NOT FALSE
                                                                  AND st_contains(geometry_value, geometry);
END;
$$ LANGUAGE plpgsql;


DO $$
BEGIN
  -- use imported country code for polygons if present
  UPDATE osm_polygon SET country_code = lower(imported_country_code) WHERE imported_country_code IS NOT NULL;

  -- use country grid to set country codes for containing elements
  PERFORM set_country_code_for_elements_within_geometry(lower(country_code), geometry)
          FROM country_osm_grid
          ORDER BY area ASC;

  -- finally use polygons with highest admin_levels for remaining elements without country_code
  PERFORM set_country_code_for_elements_within_geometry(lower(country_code), geometry)
          FROM osm_polygon
          WHERE admin_level <= 4;

  CREATE INDEX IF NOT EXISTS idx_osm_polygon_country_code ON osm_polygon(country_code);
  CREATE INDEX IF NOT EXISTS idx_osm_linestring_country_code ON osm_linestring(country_code);
  CREATE INDEX IF NOT EXISTS idx_osm_point_country_code ON osm_point(country_code);
END
$$ LANGUAGE plpgsql;
