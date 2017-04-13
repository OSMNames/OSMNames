-----------------------------------
--                               --
--  FUNCTIONS FOR EXPORTING DATA --
--                               --
-----------------------------------

DROP FUNCTION IF EXISTS getLanguageName(TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT) CASCADE;
CREATE FUNCTION getLanguageName(default_lang TEXT, fr TEXT, en TEXT, de TEXT, es TEXT, ru TEXT, zh TEXT)
RETURNS TEXT AS $$
BEGIN
  RETURN CASE
    WHEN en NOT IN ('') THEN en
    WHEN default_lang NOT IN ('') THEN default_lang
    WHEN fr NOT IN ('') THEN fr
    WHEN de NOT IN ('') THEN de
    WHEN es NOT IN ('') THEN es
    WHEN ru NOT IN ('') THEN ru
    WHEN zh NOT IN ('') THEN zh
    ELSE ''
  END;
END;
$$ LANGUAGE plpgsql IMMUTABLE;


DROP FUNCTION IF EXISTS getTypeForRelations(BIGINT, TEXT, INTEGER);
CREATE OR REPLACE FUNCTION getTypeForRelations(linked_osm_id BIGINT, type_value TEXT, place_rank INTEGER) returns TEXT as $$
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
      getLanguageName(name, name_fr, name_en, name_de, name_es, name_ru, name_zh),
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



DROP FUNCTION IF EXISTS country_name(VARCHAR);
CREATE FUNCTION country_name(country_code_in VARCHAR(2)) returns TEXT as $$
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
CREATE OR REPLACE FUNCTION get_importance(place_rank int, wikipedia VARCHAR, country_code VARCHAR(2)) returns double precision as $$
DECLARE
  langs TEXT[];
  i INT;
  wiki_article_title TEXT;
  wiki_article_language TEXT;
  result double precision;
BEGIN

  wiki_article_title := replace(split_part(wikipedia, ':', 2),' ','_');
  wiki_article_language := split_part(wikipedia, ':', 1);

  SELECT importance FROM wikipedia_article WHERE language = wiki_article_language AND title = wiki_article_title ORDER BY importance DESC LIMIT 1 INTO result;
  IF result IS NOT NULL THEN
    return result;
  END IF;

  langs := ARRAY['english','country','ar','bg','ca','cs','da','de','en','es','eo','eu','fa','fr','ko','hi','hr','id','it','he','lt','hu','ms','nl','ja','no','pl','pt','kk','ro','ru','sk','sl','sr','fi','sv','tr','uk','vi','vo','war','zh'];
  i := 1;

  WHILE langs[i] IS NOT NULL LOOP

  -- try default language for this country, English and then every other language for possible match
    wiki_article_language := CASE WHEN langs[i] = 'english' THEN 'en' WHEN langs[i] = 'country' THEN get_country_language_code(country_code) ELSE langs[i] END;

  SELECT importance FROM wikipedia_article WHERE language = wiki_article_language AND title = wiki_article_title ORDER BY importance DESC LIMIT 1 INTO result;
    IF result IS NOT NULL THEN
      return result;
    END IF;

      IF result IS NOT NULL THEN
        return result;
      END IF;
    i := i + 1;
  END LOOP;
  -- return default calculated value if no match found
    IF place_rank IS NOT NULL THEN
      return 0.75-(place_rank::double precision/40);
    END IF;
  RETURN NULL;
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


DROP FUNCTION IF EXISTS getNameForRelations(BIGINT, TEXT);
CREATE FUNCTION getNameForRelations(linked_osm_id bigint, type TEXT) RETURNS TEXT AS $$
DECLARE
  retVal TEXT;
BEGIN
IF type = 'city' THEN
  SELECT getLanguageName(name, name_fr, name_en, name_de, name_es, name_ru, name_zh) FROM osm_point WHERE osm_id = linked_osm_id INTO retVal;
  ELSE
  retVal = '';
  END IF;
  return retVal;
END;
$$ LANGUAGE plpgsql IMMUTABLE;


CREATE OR REPLACE FUNCTION array_distinct(anyarray)
RETURNS anyarray AS $$
  SELECT ARRAY(SELECT DISTINCT unnest($1))
$$ LANGUAGE sql;


DROP FUNCTION IF EXISTS getAlternativesNames(TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, VARCHAR);
CREATE FUNCTION getAlternativesNames(default_lang TEXT, fr TEXT, en TEXT, de TEXT, es TEXT, ru TEXT, zh TEXT, name TEXT, delimiter character varying)
RETURNS TEXT AS $$
DECLARE
  alternativeNames TEXT[];
BEGIN
  alternativeNames := array_distinct(ARRAY[default_lang, en, fr, de, es, ru, zh]);
  alternativeNames := array_remove(alternativeNames, '');
  alternativeNames := array_remove(alternativeNames, name);
RETURN array_to_string(alternativeNames,delimiter);
END;
$$ LANGUAGE plpgsql IMMUTABLE;
