DROP FUNCTION IF EXISTS normalize_string(TEXT);
CREATE FUNCTION normalize_string(name TEXT)
RETURNS TEXT AS $$
BEGIN
  RETURN unaccent(lower(regexp_replace(name, '[ ''-\.\(\)]', '', 'g')));
END;
$$ LANGUAGE plpgsql;
