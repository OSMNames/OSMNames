-- replace tabs with whitespaces
UPDATE osm_housenumber
  SET housenumber = regexp_replace(housenumber, E'\\s+', ' ', 'g')
  WHERE housenumber LIKE '%'||chr(9)||'%';

-- replace newlines with commas
UPDATE osm_housenumber
  SET housenumber = regexp_replace(housenumber, E'\n', ', ', 'g')
  WHERE housenumber LIKE '%'||chr(10)||'%';
