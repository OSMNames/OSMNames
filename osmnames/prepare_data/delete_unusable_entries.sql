-- remove all rows where all names are empty or null values
DELETE FROM osm_polygon WHERE name = '' IS NOT FALSE;
DELETE FROM osm_point WHERE name = '' IS NOT FALSE;
DELETE FROM osm_linestring WHERE name = '' IS NOT FALSE;


--delete entries with faulty geometries from import
DELETE FROM osm_polygon WHERE ST_IsEmpty(geometry);

-- delete linestrings which are also polygons, see #162
DELETE FROM osm_linestring WHERE osm_id = ANY(SELECT osm_id FROM osm_polygon);
