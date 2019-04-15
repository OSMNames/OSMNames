--determine linked places
-- places with label tag
UPDATE osm_polygon p
  SET linked_osm_ids = array_append(linked_osm_ids, r.member_id)
FROM osm_relation_member r
WHERE r.member_type = 0
      AND r.role = 'label'
      AND p.osm_id = r.osm_id;

-- places with admin_centre tag
UPDATE osm_polygon p
  SET linked_osm_ids = array_append(linked_osm_ids, r.member_id)
FROM osm_relation_member r
  WHERE r.member_type = 0
        AND (r.role = 'admin_centre' OR r.role = 'admin_center')
        AND p.osm_id = r.osm_id;

--tag linked places
UPDATE osm_point
  SET linked = TRUE
WHERE osm_id IN (SELECT unnest(linked_osm_ids) FROM osm_polygon WHERE linked_osm_ids IS NOT NULL);
