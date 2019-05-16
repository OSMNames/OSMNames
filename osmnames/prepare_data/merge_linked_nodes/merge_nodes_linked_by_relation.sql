-- create view with polygons which have a linked node to consider
-- linked nodes are either label nodes or admin_centers with the same name, wikidata- or wikipedia ref
DROP VIEW IF EXISTS polygons_with_linked_by_relation_node;
CREATE VIEW polygons_with_linked_by_relation_node AS (
  SELECT DISTINCT ON(point.osm_id)
    polygon.id AS polygon_id,
    point.id AS linked_node_id,
    point.osm_id AS linked_node_osm_id,
    point.all_tags AS linked_node_tags,
    point.wikipedia AS linked_node_wikipedia,
    point.wikidata AS linked_node_wikidata
  FROM osm_polygon AS polygon
  INNER JOIN osm_relation_member AS relation
    ON relation.member_type = 0
      AND lower(relation.role) = ANY(ARRAY['admin_center', 'admin_centre', 'label', 'political'])
      AND polygon.osm_id = relation.osm_id
  INNER JOIN osm_point AS point
    ON point.osm_id = relation.member_id
  WHERE
  -- include all pairs where on of the following conditions are met
  (
    lower(relation.role) = 'label'
    OR lower(relation.role) = 'political'
    OR (point.wikidata != '' AND point.wikidata = polygon.wikidata)
    OR (point.wikipedia != '' AND point.wikipedia = polygon.wikipedia)
    OR get_names(point.all_tags) && get_names(polygon.all_tags)
  )
  -- exclude all pairs where both wiki refs are set but differ
  AND NOT (
    (NULLIF(point.wikipedia, '') IS NOT NULL AND NULLIF(polygon.wikipedia, '') IS NOT NULL AND point.wikipedia != polygon.wikipedia)
    OR
    (NULLIF(point.wikidata, '') IS NOT NULL AND NULLIF(polygon.wikidata, '') IS NOT NULL AND point.wikidata != polygon.wikidata)
  )
  ORDER BY point.osm_id, polygon.place_rank DESC
);

-- update all polygons with the data of the corresponding linked node
UPDATE osm_polygon AS polygon
SET merged_osm_id = linked_node_osm_id,
    all_tags = polygon.all_tags || linked_node_tags,
    wikipedia = COALESCE(NULLIF(polygon.wikipedia, ''), linked_node_wikipedia),
    wikidata = COALESCE(NULLIF(polygon.wikidata, ''), linked_node_wikidata)
FROM polygons_with_linked_by_relation_node
WHERE polygon_id = polygon.id;

UPDATE osm_point
  SET merged = true
  WHERE id = ANY(SELECT linked_node_id FROM polygons_with_linked_by_relation_node);

DROP VIEW polygons_with_linked_by_relation_node;
