-- remove all rows where all names are empty or null values
DELETE FROM osm_polygon WHERE name = '' IS NOT FALSE;
DELETE FROM osm_point WHERE name = '' IS NOT FALSE;
DELETE FROM osm_linestring WHERE name = '' IS NOT FALSE;

-- remove tabs, so the export in tsv is valid
UPDATE osm_polygon SET name =  regexp_replace(name,'\t', ' ') WHERE name LIKE '%'||chr(9)||'%';
UPDATE osm_point SET name =  regexp_replace(name,'\t', ' ') WHERE name LIKE '%'||chr(9)||'%';
UPDATE osm_linestring SET name =  regexp_replace(name,'\t', ' ') WHERE name LIKE '%'||chr(9)||'%';


--delete entries with faulty geometries from import
DELETE FROM osm_polygon WHERE ST_IsEmpty(geometry);
