UPDATE osm_housenumber AS housenumber
  SET street = relation.name
FROM osm_relation_member AS relation_member
  INNER JOIN osm_relation AS relation
    ON relation.type = 'associatedStreet'
       OR relation.type = 'street'
WHERE relation_member.member_id = housenumber.osm_id
      AND relation_member.osm_id = relation.osm_id;
