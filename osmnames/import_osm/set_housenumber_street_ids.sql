UPDATE osm_housenumber AS housenumber
  SET street_id = street.id
FROM osm_linestring AS street
WHERE street.parent_id = housenumber.parent_id
      AND street.name = housenumber.street;
