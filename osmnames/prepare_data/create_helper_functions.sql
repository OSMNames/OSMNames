CREATE OR REPLACE FUNCTION normalize_string(name TEXT)
RETURNS TEXT AS $$
BEGIN
  RETURN unaccent(lower(regexp_replace(name, '[ ''-\.\(\)]', '', 'g')));
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION get_names(all_tags HSTORE)
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

-- if parallelize=True is set from Python, the caller query will be duplicated
-- to allow parallel execution
CREATE OR REPLACE FUNCTION auto_modulo(id INT, divisor INT = 1, remain INT = 0)
RETURNS boolean AS $$
BEGIN
  RETURN id % divisor = remain;
END;
$$ LANGUAGE plpgsql IMMUTABLE;
