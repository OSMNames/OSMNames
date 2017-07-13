UPDATE osm_housenumber AS housenumber
  SET street_id = COALESCE(street.merged_into, street.id)
FROM osm_linestring AS street
WHERE (street.parent_id = housenumber.parent_id OR housenumber.parent_id = ANY(street.intersecting_polygon_ids))
      AND street.name = housenumber.street
      AND housenumber.street_id IS NULL;
