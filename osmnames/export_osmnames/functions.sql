-----------------------------------
--                               --
--  FUNCTIONS FOR EXPORTING DATA --
--                               --
-----------------------------------


DROP FUNCTION IF EXISTS get_type_for_relations(BIGINT, TEXT, INTEGER);
CREATE OR REPLACE FUNCTION get_type_for_relations(linked_osm_id BIGINT, type_value TEXT, place_rank INTEGER) returns TEXT as $$
DECLARE
  retVal TEXT;
BEGIN
IF linked_osm_id IS NOT NULL AND type_value = 'administrative' AND (place_rank = 16 OR place_rank = 12) THEN
  SELECT type FROM osm_point WHERE osm_id = linked_osm_id INTO retVal;
  IF retVal = 'city' THEN
  RETURN retVal;
  ELSE
  RETURN type_value;
  END IF;
ELSE
  return type_value;
 END IF;
END;
$$ LANGUAGE plpgsql IMMUTABLE;


CREATE OR REPLACE FUNCTION determine_class(type TEXT)
RETURNS TEXT AS $$
BEGIN
  RETURN CASE
    WHEN type IN ('motorway','motorway_link','trunk','trunk_link','primary','primary_link','secondary','secondary_link','tertiary','tertiary_link',
                  'unclassified','residential','road','living_street','raceway','construction','track','service','path','cycleway',
                  'steps','bridleway','footway','corridor','crossing') THEN 'highway'
    WHEN type IN ('river','riverbank','stream','canal','drain','ditch') THEN 'waterway'
    WHEN type IN ('mountain_range','water','bay','desert','peak','volcano','hill') THEN 'natural'
    WHEN type IN ('administrative', 'postal_code') THEN 'boundary'
    WHEN type IN ('city','borough','suburb','quarter','neighbourhood','town','village','hamlet',
                  'island','ocean','sea','continent','country','state') THEN 'place'
    WHEN type IN ('residential','reservoir') THEN 'landuse'
    ELSE 'multiple'
  END;
END;
$$ LANGUAGE plpgsql IMMUTABLE;


DROP FUNCTION IF EXISTS get_parent_info(TEXT, BIGINT, INTEGER);
CREATE FUNCTION get_parent_info(display_name TEXT, polygon_id BIGINT, current_rank INTEGER) RETURNS parentInfo AS $$
DECLARE
  retVal parentInfo;
  current_name TEXT;
  current_parent_id BIGINT;
BEGIN
  current_name := display_name;
  retVal.displayName := current_name;

  IF current_rank BETWEEN 16 AND 20 THEN
    retVal.city := retVal.displayName;
  ELSIF current_rank BETWEEN 12 AND 15 THEN
    retVal.county := retVal.displayName;
  ELSIF current_rank BETWEEN 8 AND 11 THEN
    retVal.state := retVal.displayName;
  END IF;

  current_parent_id := polygon_id;
  WHILE current_rank >= 8 AND current_parent_id IS NOT NULL LOOP
    SELECT
      name,
      place_rank,
      parent_id
    FROM osm_polygon
    WHERE id = current_parent_id
    INTO current_name, current_rank, current_parent_id;

    IF current_name IS NOT NULL THEN
      retVal.displayName := retVal.displayName || ', ' || current_name;
    END IF;

    IF current_rank BETWEEN 16 AND 20 THEN
      retVal.city := current_name;
    ELSIF current_rank BETWEEN 12 AND 15 THEN
      retVal.county := current_name;
    ELSIF current_rank BETWEEN 8 AND 11 THEN
      retVal.state := current_name;
    END IF;
  END LOOP;
RETURN retVal;
END;
$$ LANGUAGE plpgsql IMMUTABLE;


DROP FUNCTION IF EXISTS get_country_name(VARCHAR);
CREATE FUNCTION get_country_name(country_code_in VARCHAR(2)) returns TEXT as $$
  SELECT COALESCE(name -> 'name:en',
                  name -> 'name',
                  name -> 'name:fr',
                  name -> 'name:de',
                  name -> 'name:es',
                  name -> 'name:ru',
                  name -> 'name:zh')
          FROM country_name WHERE country_code = country_code_in;
$$ LANGUAGE 'sql' IMMUTABLE;


DROP FUNCTION IF EXISTS get_importance(INTEGER, VARCHAR, VARCHAR);
CREATE FUNCTION get_importance(place_rank INT, wikipedia VARCHAR, country_code VARCHAR(2)) RETURNS DOUBLE PRECISION as $$
DECLARE
  wiki_article_title TEXT;
  wiki_article_language VARCHAR;
  country_language_code VARCHAR(2);
  result double precision;
BEGIN
  wiki_article_title := replace(split_part(wikipedia, ':', 2),' ','_');
  wiki_article_language := split_part(wikipedia, ':', 1);
  country_language_code = get_country_language_code(country_code);

  SELECT importance
  FROM wikipedia_article
  WHERE title = wiki_article_title
  ORDER BY (language = wiki_article_language) DESC,
           (language = country_language_code) DESC,
           (language = 'en') DESC,
           importance DESC
  LIMIT 1
  INTO result;

  IF result IS NOT NULL THEN
    RETURN result;
  ELSE
    RETURN 0.75-(place_rank::double precision/40);
  END IF;
END;
$$
LANGUAGE plpgsql IMMUTABLE;


DROP FUNCTION IF EXISTS get_country_language_code(VARCHAR);
CREATE FUNCTION get_country_language_code(country_code_in VARCHAR(2)) RETURNS TEXT
  AS $$
DECLARE
  country RECORD;
BEGIN
  FOR country IN SELECT DISTINCT country_default_language_code FROM country_name WHERE country_code = country_code_in LIMIT 1
  LOOP
    RETURN lower(country.country_default_language_code);
  END LOOP;
  RETURN NULL;
END;
$$
LANGUAGE plpgsql IMMUTABLE;


DROP FUNCTION IF EXISTS get_name_for_relations(BIGINT, TEXT);
CREATE FUNCTION get_name_for_relations(linked_osm_id bigint, type TEXT) RETURNS TEXT AS $$
DECLARE
  retVal TEXT;
BEGIN
IF type = 'city' THEN
  SELECT name FROM osm_point WHERE osm_id = linked_osm_id INTO retVal;
  ELSE
  retVal = '';
  END IF;
  return retVal;
END;
$$ LANGUAGE plpgsql IMMUTABLE;
