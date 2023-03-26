CREATE OR REPLACE FUNCTION set_country_code_for_polygons_within_geometry(country_code_in VARCHAR(2), geometry_value GEOMETRY) RETURNS VOID AS $$
BEGIN
  UPDATE osm_polygon SET country_code = country_code_in WHERE country_code = '' IS NOT FALSE
                                                              AND st_contains(geometry_value, geometry);
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION get_most_intersecting_country_code(geometry_in GEOMETRY) RETURNS VARCHAR(2) AS $$
BEGIN
  RETURN(
    SELECT lower(country_code)
    FROM country_osm_grid
    WHERE st_intersects(geometry, geometry_in)
    ORDER BY st_area(st_intersection(geometry, geometry_in)) DESC
    LIMIT 1
  );
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- use imported country code for polygons if present
UPDATE osm_polygon SET country_code = lower(imported_country_code) WHERE imported_country_code IS NOT NULL;

-- use country grid to set country codes for containing polygons
DO $$
BEGIN
  PERFORM set_country_code_for_polygons_within_geometry(lower(country_code), geometry)
          FROM country_osm_grid
          ORDER BY area ASC;
END
$$ LANGUAGE plpgsql;

-- finally use most intersecting country to set country_code
UPDATE osm_polygon
  SET country_code = get_most_intersecting_country_code(geometry)
WHERE country_code = '' IS NOT FALSE
