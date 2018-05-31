CREATE OR REPLACE FUNCTION determine_class(type TEXT)
RETURNS TEXT AS $$
BEGIN
  RETURN CASE
    WHEN type IN ('motorway','motorway_link','trunk','trunk_link','primary','primary_link','secondary','secondary_link','tertiary','tertiary_link',
                  'unclassified','residential','road','living_street','raceway','construction','track','service','path','cycleway',
                  'steps','bridleway','footway','corridor','crossing','pedestrian') THEN 'highway'
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


DROP FUNCTION IF EXISTS get_parent_info(BIGINT, TEXT);
CREATE FUNCTION get_parent_info(id BIGINT, name TEXT)
RETURNS parentInfo AS $$
DECLARE
  retval parentInfo;
  current_name TEXT;
  current_rank INTEGER;
  current_id BIGINT;
  current_type TEXT;
  current_country_code VARCHAR(2);
  city_rank INTEGER := 16;
  county_rank INTEGER := 10;
BEGIN
  current_id := id;
  retval.displayName := name;

  WHILE current_id IS NOT NULL LOOP
    SELECT p.name, p.place_rank, p.parent_id, p.type, p.country_code
    FROM osm_polygon AS p
    WHERE p.id = current_id
    INTO current_name, current_rank, current_id, current_type, current_country_code;

    IF retval.displayName = '' THEN
      retval.displayName := current_name;
    ELSE
      retval.displayName := retval.displayName || ', ' || current_name;
    END IF;

    IF current_country_code IS NOT NULL THEN
      retval.country_code := current_country_code;
    END IF;

    EXIT WHEN current_rank = 4;
    CONTINUE WHEN current_type IN ('water', 'bay', 'desert', 'reservoir', 'pedestrian');

    IF current_rank BETWEEN 16 AND 22 THEN
      retval.city := current_name;
      city_rank := current_rank;
    ELSIF (current_rank BETWEEN 10 AND city_rank) AND (retval.county IS NULL) THEN
      retval.county := current_name;
      county_rank := current_rank;
    ELSIF (current_rank BETWEEN 6 AND county_rank) THEN
      retval.state := current_name;
    END IF;
  END LOOP;

RETURN retval;
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
CREATE FUNCTION get_country_language_code(country_code_in VARCHAR(2)) RETURNS VARCHAR(2) AS $$
  SELECT lower(country_default_language_code)
         FROM country_name
         WHERE country_code = country_code_in LIMIT 1;
$$ LANGUAGE 'sql' IMMUTABLE;


DROP FUNCTION IF EXISTS get_housenumbers(BIGINT);
CREATE FUNCTION get_housenumbers(osm_id_in BIGINT) RETURNS TEXT AS $$
  SELECT string_agg(housenumber, ', ' ORDER BY housenumber ASC)
    FROM osm_housenumber
    WHERE street_id = osm_id_in;
$$ LANGUAGE 'sql' IMMUTABLE;


DROP FUNCTION IF EXISTS get_bounding_box(GEOMETRY, TEXT, INTEGER);
CREATE FUNCTION get_bounding_box(geom GEOMETRY, country_code TEXT, admin_level INTEGER)
RETURNS DECIMAL[] AS $$
DECLARE
  bounding_box DECIMAL[];
  shifted_geom GEOMETRY;
  original_geom_length DECIMAL;
  shifted_geom_length DECIMAL;
  x_min DECIMAL;
  x_max DECIMAL;
BEGIN
  -- manually set bounding box for some countries
  IF admin_level = 2 AND lower(country_code) = 'fr' THEN
    bounding_box := ARRAY[-5.225,41.333,9.55,51.2];
  ELSIF admin_level = 2 AND lower(country_code) = 'nl' THEN
    bounding_box := ARRAY[3.133,50.75,7.217,53.683];
  ELSE
    geom := ST_Transform(geom, 4326);
    shifted_geom := ST_ShiftLongitude(geom);
    original_geom_length := ST_XMAX(geom) - ST_XMIN(geom);
    shifted_geom_length := ST_XMAX(shifted_geom) - ST_XMIN(shifted_geom);

    -- if shifted geometry is less wide then original geometry,
    -- use the shifted geometry to create the bounding box (see #94)
    IF original_geom_length > shifted_geom_length THEN
      -- the cast to geography coerces the bounding box in range [-180, 180]
      geom = shifted_geom::geography;

      -- if the max x > 180 after the cast, the geometry still crossed the anti merdian
      -- which need to be handled specially (this results in a bounding box where
      -- the east longitude is smaller then the west longitude, e.g. for the United States)
      IF st_xmax(shifted_geom) >= 180 AND st_xmin(shifted_geom) < 180 THEN
        x_min = st_xmin(shifted_geom);
        x_max = st_xmax(shifted_geom) - 360;
      END IF;
    END IF;

    bounding_box := ARRAY[
                          round(COALESCE(x_min, ST_XMIN(geom)::numeric), 7),
                          round(ST_YMIN(geom)::numeric, 7),
                          round(COALESCE(x_max, ST_XMAX(geom)::numeric), 7),
                          round(ST_YMAX(geom)::numeric, 7)
                          ];
  END IF;
  return bounding_box;
END;
$$
LANGUAGE plpgsql IMMUTABLE;
