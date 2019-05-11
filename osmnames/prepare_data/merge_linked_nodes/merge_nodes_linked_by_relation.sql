-- create view with polygons which have a linked node to consider
-- linked nodes are either label nodes or admin_centers with the same name, wikidata- or wikipedia ref
DROP VIEW IF EXISTS polygons_with_linked_by_relation_node;
CREATE VIEW polygons_with_linked_by_relation_node AS (
  SELECT DISTINCT ON (point.osm_id)
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
  WHERE lower(relation.role) = 'label'
  OR lower(relation.role) = 'political'
  OR point.wikidata = polygon.wikidata
  OR point.wikipedia = polygon.wikipedia
  OR normalize_string(point.name) = normalize_string(polygon.name)
  OR normalize_string(point.all_tags -> 'official_name') = normalize_string(polygon.name)
  OR normalize_string(point.all_tags -> 'alt_name') = normalize_string(polygon.name)
  OR normalize_string(point.all_tags -> 'old_name') = normalize_string(polygon.name)
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

DELETE FROM osm_point WHERE id = ANY(SELECT linked_node_id FROM polygons_with_linked_by_relation_node);

DROP VIEW polygons_with_linked_by_relation_node;
