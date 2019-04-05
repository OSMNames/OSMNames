UPDATE osm_linestring
  SET wikipedia = to_title
  FROM wikipedia_redirect
  WHERE wikipedia_redirect.from_title = wikipedia;

UPDATE osm_point
  SET wikipedia = to_title
  FROM wikipedia_redirect
  WHERE wikipedia_redirect.from_title = wikipedia;

UPDATE osm_polygon
  SET wikipedia = to_title
  FROM wikipedia_redirect
  WHERE wikipedia_redirect.from_title = wikipedia;
