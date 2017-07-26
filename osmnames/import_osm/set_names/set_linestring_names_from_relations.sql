UPDATE osm_linestring AS street
  SET name = COALESCE(NULLIF(street_relation.street, ''), street_relation.name)
FROM osm_relation_member AS street_relation_member
  INNER JOIN osm_relation AS street_relation
    ON street_relation.osm_id = street_relation_member.osm_id
WHERE street_relation_member.member_id = street.osm_id
      AND (street_relation_member.role = 'street'
           OR street_relation_member.role = 'associatedStreet');
