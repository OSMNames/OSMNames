DROP FUNCTION IF EXISTS normalize_string(TEXT);
CREATE FUNCTION normalize_string(name TEXT)
RETURNS TEXT AS $$
BEGIN
  RETURN unaccent(lower(regexp_replace(name, '[ ''-\.\(\)]', '', 'g')));
END;
$$ LANGUAGE plpgsql;


DROP FUNCTION IF EXISTS get_names(HSTORE);
CREATE FUNCTION get_names(all_tags HSTORE)
RETURNS TEXT[] AS $$
DECLARE
  accepted_name_tags TEXT[] := ARRAY['name','name:left','name:right','int_name','loc_name','nat_name',
                                     'official_name','old_name','reg_name','short_name','alt_name'];
  names TEXT[];
BEGIN
  SELECT array_agg(DISTINCT(all_tags -> key))
    FROM unnest(akeys(all_tags)) AS key
    WHERE key LIKE 'name:__'
          OR key LIKE 'alt_name:__'
          OR key = ANY(accepted_name_tags)
          INTO names;

  RETURN names;
END;
$$ LANGUAGE plpgsql IMMUTABLE;
