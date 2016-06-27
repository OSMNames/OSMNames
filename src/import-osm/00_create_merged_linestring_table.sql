DROP TABLE IF EXISTS public.osm_merged_multi_linestring;

CREATE SEQUENCE IF NOT EXISTS osm_multilinestring_id_seq;
GRANT USAGE, SELECT ON SEQUENCE osm_multilinestring_id_seq TO osm;

CREATE TABLE  public.osm_merged_multi_linestring
(
  id integer NOT NULL DEFAULT nextval('osm_multilinestring_id_seq'::regclass),
  member_ids bigint[],
  type character varying,
  name character varying,
  name_fr character varying,
  name_en character varying,
  name_de character varying,
  name_es character varying,
  name_ru character varying,
  name_zh character varying,
  wikipedia character varying,
  geometry geometry(MultiLineString,3857),
  partition integer,
  calculated_country_code character varying(2),
  rank_search integer,
  parent_id bigint,
  CONSTRAINT osm_multilinestring_pkey PRIMARY KEY (id)
)
WITH (
  OIDS=FALSE
);
ALTER TABLE public.osm_merged_multi_linestring
  OWNER TO osm;