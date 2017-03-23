-----------------------------------
--                               --
--  FUNCTIONS FOR EXPORTING DATA --
--                               --
-----------------------------------

CREATE OR REPLACE FUNCTION getLanguageName(default_lang TEXT, fr TEXT, en TEXT, de TEXT, es TEXT, ru TEXT, zh TEXT)
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

CREATE OR REPLACE FUNCTION getTypeForRelations(linked_osm_id BIGINT, type_value TEXT, rank_search INTEGER) returns TEXT as $$
DECLARE
  retVal TEXT;
BEGIN
IF linked_osm_id IS NOT NULL AND type_value = 'administrative' AND (rank_search = 16 OR rank_search = 12) THEN
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

CREATE OR REPLACE FUNCTION road_class(type TEXT)
RETURNS TEXT AS $$
BEGIN
  RETURN CASE
    WHEN type IN (  'motorway','motorway_link','trunk','trunk_link','primary','primary_link','secondary','secondary_link','tertiary','tertiary_link',
                    'unclassified','residential','road','living_street','raceway','construction','track','service','path','cycleway',
                    'steps','bridleway','footway','corridor','crossing'
                    ) THEN 'highway'
    ELSE 'multiple'
  END;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

CREATE OR REPLACE FUNCTION city_class(type TEXT)
RETURNS TEXT AS $$
BEGIN
  RETURN CASE
    WHEN type IN ('administrative', 'postal_code') THEN 'boundary'
    WHEN type IN ('city','borough','suburb','quarter','neighbourhood','town','village','hamlet') THEN 'place'
    WHEN type IN ('residential') THEN 'landuse'
  END;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

CREATE OR REPLACE FUNCTION get_osm_type_polygon(osm_id BIGINT)
RETURNS TEXT AS $$
BEGIN
  IF osm_id > 0 THEN
    RETURN 'way';
  ELSE
    RETURN 'relation';
  END IF;  
END;
$$ LANGUAGE plpgsql IMMUTABLE;


CREATE OR REPLACE FUNCTION getParentInfo(name_value TEXT, id_value BIGINT, from_rank INTEGER, delimiter character varying(2)) RETURNS parentInfo AS $$
DECLARE
  retVal parentInfo;
  current_rank INTEGER;
  current_id BIGINT;
  currentName TEXT;
BEGIN
  current_rank := from_rank;
  retVal.displayName := name_value;
  current_id := id_value;
  
  IF current_rank = 16 THEN  
    retVal.city := retVal.displayName;
  ELSE
    retVal.city := '';
  END IF;
  IF current_rank = 12 THEN  
    retVal.county := retVal.displayName;
  ELSE
    retVal.county := '';
  END IF;
  IF current_rank = 8 THEN  
    retVal.state := retVal.displayName; 
  ELSE
    retVal.state := ''; 
  END IF;

  --RAISE NOTICE 'finding parent for % with rank %', name_value, from_rank;
  
  WHILE current_rank >= 8 LOOP
    SELECT getLanguageName(name, name_fr, name_en, name_de, name_es, name_ru, name_zh), rank_search, parent_id FROM osm_polygon  WHERE id = current_id INTO currentName, current_rank, current_id;
    IF currentName IS NOT NULL THEN
      retVal.displayName := retVal.displayName || delimiter || ' ' || currentName;
    END IF;

    IF current_rank = 16 THEN  
      retVal.city := currentName;
    END IF;
    IF current_rank = 12 THEN  
      retVal.county := currentName;
    END IF;
    IF current_rank = 8 THEN  
      retVal.state := currentName;  
    END IF;
  END LOOP;
RETURN retVal;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION countryName(partition_id int) returns TEXT as $$
  SELECT COALESCE(name -> 'name:en',name -> 'name',name -> 'name:fr',name -> 'name:de',name -> 'name:es',name -> 'name:ru',name -> 'name:zh') FROM country_name WHERE partition = partition_id;
$$ language 'sql';


CREATE OR REPLACE FUNCTION getImportance(rank_search int, wikipedia character varying, country_code VARCHAR(2)) returns double precision as $$

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
    IF rank_search IS NOT NULL THEN
      return 0.75-(rank_search::double precision/40);
    END IF;
  RETURN NULL;
END;
$$
LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION getOsmIdWithId(member_id BIGINT)
RETURNS BIGINT AS $$
DECLARE
  result BIGINT;
BEGIN
  SELECT osm_id FROM osm_linestring WHERE id=member_id  INTO result;
    RETURN result;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION getNameForRelations(linked_osm_id bigint, type TEXT) RETURNS TEXT AS $$
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
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION array_distinct(anyarray)
RETURNS anyarray AS $$
  SELECT ARRAY(SELECT DISTINCT unnest($1))
$$ LANGUAGE sql;


CREATE OR REPLACE FUNCTION getAlternativesNames(default_lang TEXT, fr TEXT, en TEXT, de TEXT, es TEXT, ru TEXT, zh TEXT, name TEXT, delimiter character varying)
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