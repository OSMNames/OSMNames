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

CREATE OR REPLACE FUNCTION road_class(type TEXT)
RETURNS TEXT AS $$
BEGIN
  RETURN CASE
    WHEN type IN ('tertiary') THEN 'tertiary'
    WHEN type IN ('trunk') THEN 'trunk'
    WHEN type IN ('steps','corridor','crossing','piste','mtb','hiking','cycleway','footway','path','bridleway') THEN 'path'
    WHEN type IN ('platform') THEN 'pedestrian'
    WHEN type IN ('secondary') THEN 'secondary'
    WHEN type IN ('service') THEN 'service'
    WHEN type IN ('construction') THEN 'construction'
    WHEN type IN ('track') THEN 'track'
    WHEN type IN ('primary') THEN 'primary'
    WHEN type IN ('motorway') THEN 'motorway'
    WHEN type IN ('rail','light_rail','subway') THEN 'major_rail'
    WHEN type IN ('hole') THEN 'golf'
    WHEN type IN ('cable_car','gondola','mixed_lift','chair_lift','drag_lift','t-bar','j-bar','platter','rope_tow','zip_line','magic_carpet','canopy') THEN 'aerialway'
    WHEN type IN ('motorway_link') THEN 'motorway_link'
    WHEN type IN ('ferry') THEN 'ferry'
    WHEN type IN ('trunk_link','primary_link','secondary_link','tertiary_link') THEN 'link'
    WHEN type IN ('unclassified','residential','road','living_street','raceway') THEN 'street'
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
      retVal.displayName := retVal.displayName || delimiter || '' || currentName;
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


CREATE OR REPLACE FUNCTION constructDisplayName(id_value BIGINT, delimiter TEXT) RETURNS TEXT AS $$
DECLARE
  displayName TEXT;
  oldName TEXT;
  currentName TEXT;
  current_id BIGINT;
BEGIN
  current_id := id_value;
  WHILE current_id IS NOT NULL LOOP
    SELECT parent_id, COALESCE(NULLIF(name_en,''), name) FROM osm_polygon WHERE id = current_id INTO current_id, currentName;
    IF displayName IS NULL THEN
  displayName := currentName;
    ELSE
      displayName := displayName || delimiter || ' ' || currentName;
    END IF;
  END LOOP;
RETURN displayName;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION constructNodeDisplayName(id_value BIGINT, delimiter TEXT, name TEXT) RETURNS TEXT AS $$
DECLARE
  displayName TEXT;
BEGIN
  SELECT constructDisplayName(id_value,',') INTO displayName;
  displayName := name || delimiter || ' ' || displayName;
  IF displayName IS NULL THEN
    return name;
  END IF;
RETURN displayName;
END;
$$ LANGUAGE plpgsql;

 CREATE OR REPLACE FUNCTION countryName(partition_id int) returns TEXT as $$
  SELECT COALESCE(name -> 'name:en',name -> 'name',name -> 'name:fr',name -> 'name:de',name -> 'name:es',name -> 'name:ru',name -> 'name:zh') FROM country_name WHERE partition = partition_id;
$$ language 'sql';

CREATE OR REPLACE FUNCTION constructSpecificParentName(id_value BIGINT, from_rank INTEGER, to_rank INTEGER) RETURNS TEXT AS $$
DECLARE
  current_id BIGINT;
  currentName TEXT;
  currentNameOld TEXT;
  current_rank INTEGER;
BEGIN
  current_rank := from_rank;
  current_id := id_value;
  currentName := '';
  currentNameOld := '';
  IF current_rank = to_rank THEN
    SELECT COALESCE(NULLIF(name_en,''), name) FROM osm_polygon WHERE id = current_id INTO currentName;
    RETURN currentName;
  END IF; 
  WHILE current_rank > to_rank  LOOP
  currentNameOld := currentName;
    SELECT parent_id, COALESCE(NULLIF(name_en,''), name), rank_search FROM osm_polygon WHERE id = current_id INTO current_id, currentName, current_rank;
    IF current_id IS NULL THEN
  RETURN '';
    END IF; 
      IF current_rank < to_rank THEN
  RETURN currentNameOld;
    END IF; 
  END LOOP;
RETURN currentName;
END;
$$ LANGUAGE plpgsql;


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


CREATE OR REPLACE FUNCTION getWikipediaURL(wikipedia character varying, country_code VARCHAR(2)) returns TEXT as $$
DECLARE
  langs TEXT[];
  i INT;
  wiki_article_title TEXT;
  wiki_article_language TEXT;
  wiki_url_part TEXT;
BEGIN
  IF wikipedia IS NULL OR wikipedia <> '' IS FALSE THEN
    RETURN '';
  END IF;
  wiki_url_part := '.wikipedia.org/wiki/';
  wiki_article_title := replace(split_part(wikipedia, ':', 2),' ','_');
  wiki_article_language := split_part(wikipedia, ':', 1);

  RETURN wiki_article_language || wiki_url_part || wiki_article_title;
END;
$$
LANGUAGE plpgsql;