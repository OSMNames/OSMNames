UPDATE osm_housenumber SET normalized_street = unaccent(lower(regexp_replace(street, '[ ''-]', '', 'g')));
UPDATE osm_linestring SET normalized_name = unaccent(lower(regexp_replace(name, '[ ''-]', '', 'g')));
