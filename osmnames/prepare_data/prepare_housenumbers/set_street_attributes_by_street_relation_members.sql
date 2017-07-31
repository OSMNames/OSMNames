UPDATE osm_housenumber AS housenumber
  SET street_id = COALESCE(street.merged_into, street.osm_id),
      street = street.name
FROM osm_relation_member AS housenumber_relation_member
  INNER JOIN osm_relation AS relation
    ON (relation.type = 'associatedStreet' OR relation.type = 'street')
       AND relation.osm_id = housenumber_relation_member.osm_id
  INNER JOIN osm_relation_member AS street_relation_member
    ON street_relation_member.role = 'street'
       AND street_relation_member.osm_id = relation.osm_id
  INNER JOIN osm_linestring AS street
    ON street.osm_id = street_relation_member.member_id
WHERE housenumber_relation_member.member_id = housenumber.osm_id
      AND housenumber.street_id IS NULL;
