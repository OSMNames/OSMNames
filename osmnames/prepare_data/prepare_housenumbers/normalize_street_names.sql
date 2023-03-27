UPDATE osm_housenumber SET normalized_street = normalize_string(street) WHERE auto_modulo(id); --&
UPDATE osm_linestring SET normalized_name = normalize_string(name) WHERE auto_modulo(id); --&
