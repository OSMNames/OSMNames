ALTER TABLE wikipedia_article OWNER TO osm;

--create index
CREATE INDEX idx_wikipedia_article_osm_id ON wikipedia_article USING btree (osm_type, osm_id);