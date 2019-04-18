UPDATE osm_polygon AS polygon SET all_tags = polygon.all_tags || label_node.all_tags,
       wikipedia = COALESCE(polygon.wikipedia, label_node.wikipedia),
       wikidata = COALESCE(polygon.wikidata, label_node.wikidata)
FROM osm_relation_member relation
JOIN osm_point AS label_node
ON label_node.osm_id = relation.member_id
WHERE relation.member_type = 0
   AND (relation.role = 'label' OR relation.role = 'political')
   AND polygon.osm_id = relation.osm_id;
