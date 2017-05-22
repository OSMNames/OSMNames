DROP VIEW IF EXISTS osm_elements_view;
CREATE VIEW osm_elements_view AS
  SELECT id, 'osm_linestring' AS osm_table, osm_id, name, country_code, parent_id FROM osm_linestring
  UNION ALL
  SELECT id, 'osm_polygon' AS osm_table, osm_id, name, country_code, parent_id FROM osm_polygon
  UNION ALL
  SELECT id, 'osm_point' AS osm_table, osm_id, name, country_code, parent_id FROM osm_point
  UNION ALL
  SELECT id, 'osm_housenumber' AS osm_table, osm_id, name, country_code, parent_id FROM osm_housenumber;
