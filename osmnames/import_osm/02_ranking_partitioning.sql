UPDATE osm_linestring SET place_rank = get_place_rank(type, osm_id);
UPDATE osm_polygon SET place_rank = get_place_rank(type, osm_id);
UPDATE osm_point SET place_rank = get_place_rank(type, osm_id);

DO $$
BEGIN
  PERFORM set_country_code_for_containing_entities(lower(imported_country_code), geometry) FROM osm_polygon WHERE place_rank = 4;
END
$$ LANGUAGE plpgsql;

--create indexes
CREATE INDEX IF NOT EXISTS idx_osm_polgyon_geom ON osm_polygon USING gist (geometry);
CREATE INDEX IF NOT EXISTS idx_osm_point_geom ON osm_point USING gist (geometry);
CREATE INDEX IF NOT EXISTS idx_osm_linestring_geom ON osm_linestring USING gist (geometry);
CREATE INDEX IF NOT EXISTS idx_osm_housenumber_geom ON osm_housenumber USING gist (geometry);
