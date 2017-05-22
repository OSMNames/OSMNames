DROP FUNCTION IF EXISTS get_alternative_names(HSTORE, TEXT);
CREATE FUNCTION get_alternative_names(all_tags HSTORE, name TEXT)
RETURNS TEXT AS $$
DECLARE
  accepted_name_tags TEXT[] := ARRAY['name:left','name:right','int_name','loc_name','nat_name',
                                     'official_name','old_name','reg_name','short_name','alt_name'];
  alternative_names TEXT[];
  alternative_names_string TEXT;
BEGIN
  SELECT array_agg(DISTINCT(all_tags -> key))
  FROM unnest(akeys(all_tags)) AS key
  WHERE key LIKE 'name:__' OR key = ANY(accepted_name_tags)
  INTO alternative_names;
  alternative_names := array_remove(alternative_names, name);
  alternative_names_string := array_to_string(alternative_names, ',');
  RETURN COALESCE(regexp_replace(alternative_names_string, E'\\s+', ' ', 'g'), '');
END;
$$ LANGUAGE plpgsql IMMUTABLE;


DROP FUNCTION IF EXISTS get_name(HSTORE);
CREATE FUNCTION get_name(all_tags HSTORE)
RETURNS TEXT AS $$
  SELECT COALESCE(
                  all_tags -> 'name:en',
                  all_tags -> 'name:fr',
                  all_tags -> 'name:de',
                  all_tags -> 'name:es',
                  all_tags -> 'name:ru',
                  all_tags -> 'name:zh',
                  split_part(get_alternative_names(all_tags, ''), ',', 1),
                  ''
                  );
$$ LANGUAGE 'sql' IMMUTABLE;


UPDATE osm_linestring SET name = get_name(all_tags) WHERE name = '' IS NOT FALSE;
UPDATE osm_polygon SET name = get_name(all_tags) WHERE name = '' IS NOT FALSE;
UPDATE osm_point SET name = get_name(all_tags) WHERE name = '' IS NOT FALSE;

UPDATE osm_linestring SET alternative_names = get_alternative_names(all_tags, name);
UPDATE osm_polygon SET alternative_names = get_alternative_names(all_tags, name);
UPDATE osm_point SET alternative_names = get_alternative_names(all_tags, name);

UPDATE osm_linestring SET name = regexp_replace(name, E'\\s+', ' ', 'g') WHERE name LIKE '%'||chr(9)||'%';
UPDATE osm_polygon SET name = regexp_replace(name, E'\\s+', ' ', 'g') WHERE name LIKE '%'||chr(9)||'%';
UPDATE osm_point SET name = regexp_replace(name, E'\\s+', ' ', 'g') WHERE name LIKE '%'||chr(9)||'%';
