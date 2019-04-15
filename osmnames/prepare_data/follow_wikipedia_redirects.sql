UPDATE osm_linestring
  SET wikipedia = to_title
  FROM wikipedia_redirect
  WHERE wikipedia_redirect.from_title = wikipedia
    OR wikipedia_redirect.from_title = concat_ws(':', 'en', split_part(wikipedia, ':', 2)); --&

UPDATE osm_point
  SET wikipedia = to_title
  FROM wikipedia_redirect
  WHERE wikipedia_redirect.from_title = wikipedia
    OR wikipedia_redirect.from_title = concat_ws(':', 'en', split_part(wikipedia, ':', 2)); --&

UPDATE osm_polygon
  SET wikipedia = to_title
  FROM wikipedia_redirect
  WHERE wikipedia_redirect.from_title = wikipedia
    OR wikipedia_redirect.from_title = concat_ws(':', 'en', split_part(wikipedia, ':', 2)); --&
