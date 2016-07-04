--determine parents
UPDATE osm_polygon SET parent_id = determineParentPlace(id, partition, rank_search, geometry);
UPDATE osm_point SET parent_id = determineParentPlace(id, partition, rank_search, geometry) WHERE linked IS FALSE;
SELECT determineRoadHierarchyForEachCountry();

-- create index for faster processing
--CREATE INDEX IF NOT EXISTS idx_linestring_name_parent ON osm_linestring (name,parent_id);
