DROP FUNCTION IF EXISTS get_alternative_names(HSTORE, TEXT);
CREATE FUNCTION get_alternative_names(all_tags HSTORE, name TEXT)
RETURNS TEXT AS $$
DECLARE
  alternative_names TEXT[];
BEGIN
  SELECT array_agg(DISTINCT(all_tags -> key))
  FROM unnest(akeys(all_tags)) AS key
  WHERE (key LIKE 'name:%' OR key LIKE '%[_]name') AND (key NOT ILIKE name)
  INTO alternative_names;
  RETURN COALESCE(array_to_string(alternative_names, ','), '');
END;
$$ LANGUAGE plpgsql IMMUTABLE;


DROP FUNCTION IF EXISTS get_name(HSTORE);
CREATE FUNCTION get_name(all_tags HSTORE)
RETURNS TEXT AS $$
  SELECT COALESCE(all_tags -> 'name:en',
                  all_tags -> 'name:fr',
                  all_tags -> 'name:de',
                  all_tags -> 'name:es',
                  all_tags -> 'name:ru',
                  all_tags -> 'name:zh',
                  split_part(get_alternative_names(all_tags, ''), ',', 1),
                  '');
$$ LANGUAGE 'sql' IMMUTABLE;


UPDATE osm_linestring SET name = get_name(all_tags) WHERE name = '' IS NOT FALSE;
UPDATE osm_polygon SET name = get_name(all_tags) WHERE name = '' IS NOT FALSE;
UPDATE osm_point SET name = get_name(all_tags) WHERE name = '' IS NOT FALSE;


UPDATE osm_linestring SET alternative_names = get_alternative_names(all_tags, name);
UPDATE osm_polygon SET alternative_names = get_alternative_names(all_tags, name);
UPDATE osm_point SET alternative_names = get_alternative_names(all_tags, name);