-- cleanup unusable entries
-- remove all rows where all names are empty or null values
DELETE FROM osm_polygon_tmp WHERE (name = '' AND name_fr = '' AND name_en = '' AND name_de = '' AND name_es = '' AND name_ru = '' AND name_zh = '') IS NOT FALSE;
DELETE FROM osm_point_tmp WHERE (name = '' AND name_fr = '' AND name_en = '' AND name_de = '' AND name_es = '' AND name_ru = '' AND name_zh = '') IS NOT FALSE;
DELETE FROM osm_linestring_tmp WHERE (name = '' AND name_fr = '' AND name_en = '' AND name_de = '' AND name_es = '' AND name_ru = '' AND name_zh = '') IS NOT FALSE;

-- remove tabs, so the export in tsv is valid
UPDATE osm_polygon_tmp SET name =  regexp_replace(name,'\t', ' ') WHERE name LIKE '%'||chr(9)||'%';
UPDATE osm_polygon_tmp SET name_fr =  regexp_replace(name_fr,'\t', ' ') WHERE name_fr LIKE '%'||chr(9)||'%';
UPDATE osm_polygon_tmp SET name_en =  regexp_replace(name_en,'\t', ' ') WHERE name_en LIKE '%'||chr(9)||'%';
UPDATE osm_polygon_tmp SET name_de =  regexp_replace(name_de,'\t', ' ') WHERE name_de LIKE '%'||chr(9)||'%';
UPDATE osm_polygon_tmp SET name_es =  regexp_replace(name_es,'\t', ' ') WHERE name_es LIKE '%'||chr(9)||'%';
UPDATE osm_polygon_tmp SET name_ru =  regexp_replace(name_ru,'\t', ' ') WHERE name_ru LIKE '%'||chr(9)||'%';
UPDATE osm_polygon_tmp SET name_zh =  regexp_replace(name_zh,'\t', ' ') WHERE name_zh LIKE '%'||chr(9)||'%';

UPDATE osm_point_tmp SET name =  regexp_replace(name,'\t', ' ') WHERE name LIKE '%'||chr(9)||'%';
UPDATE osm_point_tmp SET name_fr =  regexp_replace(name_fr,'\t', ' ') WHERE name_fr LIKE '%'||chr(9)||'%';
UPDATE osm_point_tmp SET name_en =  regexp_replace(name_en,'\t', ' ') WHERE name_en LIKE '%'||chr(9)||'%';
UPDATE osm_point_tmp SET name_de =  regexp_replace(name_de,'\t', ' ') WHERE name_de LIKE '%'||chr(9)||'%';
UPDATE osm_point_tmp SET name_es =  regexp_replace(name_es,'\t', ' ') WHERE name_es LIKE '%'||chr(9)||'%';
UPDATE osm_point_tmp SET name_ru =  regexp_replace(name_ru,'\t', ' ') WHERE name_ru LIKE '%'||chr(9)||'%';
UPDATE osm_point_tmp SET name_zh =  regexp_replace(name_zh,'\t', ' ') WHERE name_zh LIKE '%'||chr(9)||'%';

UPDATE osm_linestring_tmp SET name =  regexp_replace(name,'\t', ' ') WHERE name LIKE '%'||chr(9)||'%';
UPDATE osm_linestring_tmp SET name_fr =  regexp_replace(name_fr,'\t', ' ') WHERE name_fr LIKE '%'||chr(9)||'%';
UPDATE osm_linestring_tmp SET name_en =  regexp_replace(name_en,'\t', ' ') WHERE name_en LIKE '%'||chr(9)||'%';
UPDATE osm_linestring_tmp SET name_de =  regexp_replace(name_de,'\t', ' ') WHERE name_de LIKE '%'||chr(9)||'%';
UPDATE osm_linestring_tmp SET name_es =  regexp_replace(name_es,'\t', ' ') WHERE name_es LIKE '%'||chr(9)||'%';
UPDATE osm_linestring_tmp SET name_ru =  regexp_replace(name_ru,'\t', ' ') WHERE name_ru LIKE '%'||chr(9)||'%';
UPDATE osm_linestring_tmp SET name_zh =  regexp_replace(name_zh,'\t', ' ') WHERE name_zh LIKE '%'||chr(9)||'%';

--delete entries with faulty geometries from import
DELETE FROM osm_polygon_tmp WHERE ST_IsEmpty(geometry);
