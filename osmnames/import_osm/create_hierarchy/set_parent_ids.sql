DROP FUNCTION IF EXISTS set_parent_id_for_elements_within_geometry(BIGINT, INT, geometry);
CREATE FUNCTION set_parent_id_for_elements_within_geometry(id_in BIGINT, place_rank_in INT, geometry_in GEOMETRY)
RETURNS VOID AS $$
BEGIN
  UPDATE osm_polygon SET parent_id = id_in WHERE parent_id IS NULL
                                                 AND id_in != id
                                                 AND st_contains(geometry_in, geometry_center)
                                                 AND COALESCE(place_rank, 100) > COALESCE(place_rank_in, -1);

  UPDATE osm_housenumber SET parent_id = id_in WHERE parent_id IS NULL
                                                     AND id_in != id
                                                     AND st_contains(geometry_in, geometry_center);

  UPDATE osm_point SET parent_id = id_in WHERE parent_id IS NULL
                                               AND id_in != id
                                               AND st_contains(geometry_in, geometry)
                                               AND linked IS FALSE;


  UPDATE osm_linestring SET parent_id = id_in WHERE parent_id IS NULL
                                                    AND id_in != id
                                                    AND st_contains(geometry_in, geometry_center);
END;
$$ LANGUAGE plpgsql;

CREATE INDEX IF NOT EXISTS idx_osm_polygon_place_rank ON osm_polygon(place_rank);

DO $$
BEGIN
  PERFORM set_parent_id_for_elements_within_geometry(id, place_rank, geometry)
          FROM osm_polygon
          WHERE place_rank <= 22 AND type NOT IN ('water', 'desert', 'bay', 'reservoir')
          ORDER BY place_rank DESC;
END
$$ LANGUAGE plpgsql;
