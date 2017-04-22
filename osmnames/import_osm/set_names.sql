-- Order of priority for 'name' is: default name, en, fr, de, es, ru, zh
DROP FUNCTION IF EXISTS get_name(HSTORE);
CREATE FUNCTION get_name(all_tags HSTORE) RETURNS TEXT AS $$
  SELECT COALESCE(all_tags -> 'name:en',
                  all_tags -> 'name:fr',
                  all_tags -> 'name:de',
                  all_tags -> 'name:es',
                  all_tags -> 'name:ru',
                  all_tags -> 'name:zh');
$$ LANGUAGE 'sql' IMMUTABLE;



CREATE OR REPLACE FUNCTION array_distinct(anyarray)
RETURNS anyarray AS $$
  SELECT ARRAY(SELECT DISTINCT unnest($1))
$$ LANGUAGE sql;


/*  Get values for all the name tags as defined in http://wiki.openstreetmap.org/wiki/Key:name
    The alternative_names string will contain all distinct names except the one already set as 'name' */
DROP FUNCTION IF EXISTS get_alternative_names(HSTORE, TEXT, VARCHAR);
CREATE FUNCTION get_alternative_names(all_tags HSTORE, name TEXT, delimiter character varying)
RETURNS TEXT AS $$
DECLARE
  alternative_names TEXT[];
  key TEXT;
BEGIN
  FOREACH key in ARRAY akeys(all_tags)
  LOOP
    IF (key LIKE 'name:%' OR key LIKE '%[_]name') AND (all_tags->key NOT ILIKE name)
    THEN
      alternative_names := array_append(alternative_names, all_tags->key);
    END IF;
  END LOOP;
  alternative_names := array_distinct(alternative_names);
RETURN array_to_string(alternative_names, delimiter);
END;
$$ LANGUAGE plpgsql IMMUTABLE;


-- If the 'name' is empty or null, get name in another available language
UPDATE osm_linestring SET name = get_name(all_tags) WHERE name = '' IS NOT FALSE;
UPDATE osm_polygon SET name = get_name(all_tags) WHERE name = '' IS NOT FALSE;
UPDATE osm_point SET name = get_name(all_tags) WHERE name = '' IS NOT FALSE;


-- Get all alternative names, concatenated as a string, separated by commas
UPDATE osm_linestring SET alternative_names = get_alternative_names(all_tags, name, ',');
UPDATE osm_polygon SET alternative_names = get_alternative_names(all_tags, name, ',');
UPDATE osm_point SET alternative_names = get_alternative_names(all_tags, name, ',');