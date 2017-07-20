UPDATE osm_housenumber SET normalized_street = lower(regexp_replace(street, '[ -]', '', 'g'));
UPDATE osm_linestring SET normalized_name = lower(regexp_replace(name, '[ -]', '', 'g'));
