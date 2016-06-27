-- Alter tables for parent ids calculation
ALTER TABLE osm_polygon 
  DROP COLUMN IF EXISTS partition CASCADE,
  DROP COLUMN IF EXISTS calculated_country_code CASCADE,
  DROP COLUMN IF EXISTS linked_osm_id CASCADE,
  DROP COLUMN IF EXISTS rank_search CASCADE,
  DROP COLUMN IF EXISTS parent_id CASCADE;
ALTER TABLE osm_point
  DROP COLUMN IF EXISTS partition CASCADE,
  DROP COLUMN IF EXISTS calculated_country_code CASCADE,
  DROP COLUMN IF EXISTS rank_search CASCADE,
  DROP COLUMN IF EXISTS linked CASCADE,
  DROP COLUMN IF EXISTS parent_id CASCADE;
ALTER TABLE osm_linestring
  DROP COLUMN IF EXISTS partition CASCADE,
  DROP COLUMN IF EXISTS calculated_country_code CASCADE,
  DROP COLUMN IF EXISTS rank_search CASCADE,
  DROP COLUMN IF EXISTS parent_id CASCADE,
  DROP COLUMN IF EXISTS merged CASCADE;

-- Alter tables for parent ids calculation
ALTER TABLE osm_polygon 
  ADD COLUMN partition integer,
  ADD COLUMN calculated_country_code character varying(2),
  ADD COLUMN linked_osm_id bigint,
  ADD COLUMN rank_search int,
  ADD COLUMN parent_id bigint;
ALTER TABLE osm_point
  ADD COLUMN partition integer,
  ADD COLUMN calculated_country_code character varying(2),
  ADD COLUMN rank_search int,
  ADD COLUMN linked BOOLEAN DEFAULT FALSE,
  ADD COLUMN parent_id bigint;
ALTER TABLE osm_linestring
  ADD COLUMN partition integer,
  ADD COLUMN calculated_country_code character varying(2),
  ADD COLUMN rank_search int,
  ADD COLUMN parent_id bigint,
  ADD COLUMN merged BOOLEAN DEFAULT FALSE;