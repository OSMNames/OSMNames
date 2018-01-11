ALTER TABLE osm_linestring ADD COLUMN parent_id BIGINT;
ALTER TABLE osm_linestring ADD COLUMN place_rank INTEGER;
ALTER TABLE osm_linestring ADD COLUMN alternative_names TEXT;
ALTER TABLE osm_linestring ADD COLUMN merged_into BIGINT;
ALTER TABLE osm_linestring ADD COLUMN geometry_center GEOMETRY;
ALTER TABLE osm_linestring ADD COLUMN normalized_name TEXT;

ALTER TABLE osm_polygon ADD COLUMN parent_id BIGINT;
ALTER TABLE osm_polygon ADD COLUMN place_rank INTEGER;
ALTER TABLE osm_polygon ADD COLUMN linked_osm_ids BIGINT[];
ALTER TABLE osm_polygon ADD COLUMN alternative_names TEXT;
ALTER TABLE osm_polygon ADD COLUMN country_code VARCHAR(2);

ALTER TABLE osm_point ADD COLUMN parent_id BIGINT;
ALTER TABLE osm_point ADD COLUMN place_rank INTEGER;
ALTER TABLE osm_point ADD COLUMN alternative_names TEXT;
ALTER TABLE osm_point ADD COLUMN linked BOOL DEFAULT FALSE;

ALTER TABLE osm_housenumber ADD COLUMN parent_id BIGINT;
ALTER TABLE osm_housenumber ADD COLUMN street_id BIGINT;
ALTER TABLE osm_housenumber ADD COLUMN normalized_street TEXT;
ALTER TABLE osm_housenumber ADD COLUMN geometry_center GEOMETRY;
