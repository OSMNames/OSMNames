--cleanup unusable entries
DELETE FROM osm_polygon_tmp WHERE (name <> '' OR name_fr <> '' OR name_en <> '' OR name_de <> '' OR name_es <> '' OR name_ru <> '' OR name_zh <> '') IS FALSE;
DELETE FROM osm_point_tmp WHERE (name <> '' OR name_fr <> '' OR name_en <> '' OR name_de <> '' OR name_es <> '' OR name_ru <> '' OR name_zh <> '') IS FALSE;
DELETE FROM osm_linestring_tmp WHERE (name <> '' OR name_fr <> '' OR name_en <> '' OR name_de <> '' OR name_es <> '' OR name_ru <> '' OR name_zh <> '') IS FALSE;

--remove tabs, so the export in tsv is valid
SELECT regexp_replace(name,'\t', '') , * FROM osm_polygon_tmp WHERE name LIKE '%'||chr(9)||'%';
SELECT regexp_replace(name_fr,'\t', '') , * FROM osm_polygon_tmp WHERE name_fr LIKE '%'||chr(9)||'%';
SELECT regexp_replace(name_en,'\t', '') , * FROM osm_polygon_tmp WHERE name_en LIKE '%'||chr(9)||'%';
SELECT regexp_replace(name_de,'\t', '') , * FROM osm_polygon_tmp WHERE name_de LIKE '%'||chr(9)||'%';
SELECT regexp_replace(name_es,'\t', '') , * FROM osm_polygon_tmp WHERE name_es LIKE '%'||chr(9)||'%';
SELECT regexp_replace(name_ru,'\t', '') , * FROM osm_polygon_tmp WHERE name_ru LIKE '%'||chr(9)||'%';
SELECT regexp_replace(name_zh,'\t', '') , * FROM osm_polygon_tmp WHERE name_zh LIKE '%'||chr(9)||'%';

SELECT regexp_replace(name,'\t', '') , * FROM osm_point_tmp WHERE name LIKE '%'||chr(9)||'%';
SELECT regexp_replace(name_fr,'\t', '') , * FROM osm_point_tmp WHERE name_fr LIKE '%'||chr(9)||'%';
SELECT regexp_replace(name_en,'\t', '') , * FROM osm_point_tmp WHERE name_en LIKE '%'||chr(9)||'%';
SELECT regexp_replace(name_de,'\t', '') , * FROM osm_point_tmp WHERE name_de LIKE '%'||chr(9)||'%';
SELECT regexp_replace(name_es,'\t', '') , * FROM osm_point_tmp WHERE name_es LIKE '%'||chr(9)||'%';
SELECT regexp_replace(name_ru,'\t', '') , * FROM osm_point_tmp WHERE name_ru LIKE '%'||chr(9)||'%';
SELECT regexp_replace(name_zh,'\t', '') , * FROM osm_point_tmp WHERE name_zh LIKE '%'||chr(9)||'%';

SELECT regexp_replace(name,'\t', '') , * FROM osm_linestring_tmp WHERE name LIKE '%'||chr(9)||'%';
SELECT regexp_replace(name_fr,'\t', '') , * FROM osm_linestring_tmp WHERE name_fr LIKE '%'||chr(9)||'%';
SELECT regexp_replace(name_en,'\t', '') , * FROM osm_linestring_tmp WHERE name_en LIKE '%'||chr(9)||'%';
SELECT regexp_replace(name_de,'\t', '') , * FROM osm_linestring_tmp WHERE name_de LIKE '%'||chr(9)||'%';
SELECT regexp_replace(name_es,'\t', '') , * FROM osm_linestring_tmp WHERE name_es LIKE '%'||chr(9)||'%';
SELECT regexp_replace(name_ru,'\t', '') , * FROM osm_linestring_tmp WHERE name_ru LIKE '%'||chr(9)||'%';
SELECT regexp_replace(name_zh,'\t', '') , * FROM osm_linestring_tmp WHERE name_zh LIKE '%'||chr(9)||'%';