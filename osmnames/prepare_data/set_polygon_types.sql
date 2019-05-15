-- The types of the polygons are already set from the imposm import.
-- Here, libpostals fine-granular mapping between admin_level and type
-- is used to improve the quality for elements with the type 'administrative', see issue #158
UPDATE osm_polygon AS polygon
  SET type = mapping.type
FROM admin_level_type_mapping AS mapping
WHERE mapping.country_code = polygon.country_code
  AND mapping.admin_level = polygon.admin_level
  AND polygon.admin_level IS NOT NULL
  AND polygon.type = 'administrative';
