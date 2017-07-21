-- remove all rows where all names are empty or null values
DELETE FROM osm_polygon WHERE name = '' IS NOT FALSE;
DELETE FROM osm_point WHERE name = '' IS NOT FALSE;
DELETE FROM osm_linestring WHERE name = '' IS NOT FALSE;


--delete entries with faulty geometries from import
DELETE FROM osm_polygon WHERE ST_IsEmpty(geometry);
