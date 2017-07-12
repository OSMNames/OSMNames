DROP FUNCTION IF EXISTS set_parent_id_for_elements_within_geometry(BIGINT, INT, geometry);
CREATE FUNCTION set_parent_id_for_elements_within_geometry(id_in BIGINT, place_rank_in INT, geometry_in GEOMETRY)
RETURNS VOID AS $$
BEGIN
  UPDATE osm_polygon SET parent_id = id_in WHERE parent_id IS NULL
                                                 AND id_in != id
                                                 AND st_contains(geometry_in, geometry)
                                                 AND COALESCE(place_rank, 100) >= COALESCE(place_rank_in, -1);

  UPDATE osm_housenumber SET parent_id = id_in WHERE parent_id IS NULL
                                                     AND id_in != id
                                                     AND st_contains(geometry_in, geometry);

  UPDATE osm_point SET parent_id = id_in WHERE parent_id IS NULL
                                               AND id_in != id
                                               AND st_contains(geometry_in, geometry)
                                               AND linked IS FALSE;


  -- setting the parent_id of linestrings makes only sense when the polygons place_rank is >= 22
  -- Because a linestring is likely to intersect multiple polygons with small place ranks,
  -- it will only be fully covered by a polygon with a small place rank, which is not the correct parent
  -- the parent for the remaining linestrings will be set later
  IF place_rank_in >= 22 THEN
    UPDATE osm_linestring SET parent_id = id_in WHERE parent_id IS NULL
                                                      AND id_in != id
                                                      AND st_contains(geometry_in, geometry);
  END IF;
END;
$$ LANGUAGE plpgsql;

DO $$
BEGIN
  PERFORM set_parent_id_for_elements_within_geometry(id, place_rank, geometry)
          FROM osm_polygon
          WHERE place_rank <= 22 AND type NOT IN ('water', 'desert', 'bay', 'reservoir')
          ORDER BY place_rank DESC;
END
$$ LANGUAGE plpgsql;
