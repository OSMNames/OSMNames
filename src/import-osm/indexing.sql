--cleanup unusable entries
DELETE FROM osm_polygon WHERE (name <> '' OR name_fr <> '' OR name_en <> '' OR name_de <> '' OR name_es <> '' OR name_ru <> '' OR name_zh <> '') IS FALSE;
DELETE FROM osm_point WHERE (name <> '' OR name_fr <> '' OR name_en <> '' OR name_de <> '' OR name_es <> '' OR name_ru <> '' OR name_zh <> '') IS FALSE;
DELETE FROM osm_linestring WHERE (name <> '' OR name_fr <> '' OR name_en <> '' OR name_de <> '' OR name_es <> '' OR name_ru <> '' OR name_zh <> '') IS FALSE;

--create triggers for partitioning
DROP TRIGGER IF EXISTS performCountryAndPartitionUpdate_polygon ON osm_polygon;
CREATE TRIGGER performCountryAndPartitionUpdate_polygon
    BEFORE UPDATE OF rank_search ON osm_polygon
    FOR EACH ROW
    EXECUTE PROCEDURE determineCountryCodeAndPartition();

DROP TRIGGER IF EXISTS performCountryAndPartitionUpdate_point ON osm_point;
CREATE TRIGGER performCountryAndPartitionUpdate_point
    BEFORE UPDATE OF rank_search ON osm_point
    FOR EACH ROW
    EXECUTE PROCEDURE determineCountryCodeAndPartition();

DROP TRIGGER IF EXISTS performCountryAndPartitionUpdate_linestring ON osm_linestring;
CREATE TRIGGER performCountryAndPartitionUpdate_linestring
    BEFORE UPDATE OF rank_search ON osm_linestring
    FOR EACH ROW
    EXECUTE PROCEDURE determineCountryCodeAndPartition();

--create triggers for merging streets
DROP TRIGGER IF EXISTS updateMergeFlagWhenLinestringInsert ON osm_merged_multi_linestring;
CREATE TRIGGER updateMergeFlagWhenLinestringInsert BEFORE INSERT ON osm_merged_multi_linestring
    FOR EACH ROW EXECUTE PROCEDURE updateMergedFlag();

--do the ranking and partitioning
UPDATE osm_polygon SET rank_search = rank_place(type, osm_id) WHERE rank_search IS NULL;
UPDATE osm_point SET rank_search = rank_place(type, osm_id) WHERE rank_search IS NULL;
UPDATE osm_linestring SET rank_search = rank_address(type, osm_id) WHERE rank_search IS NULL;

--determine linked places
-- places with admin_centre tag
UPDATE osm_polygon p
	SET linked_osm_id = r.member         
	FROM osm_relation r                                     
	WHERE 
	r.type = 0 AND r.role = 'admin_centre' 
	AND p.osm_id = r.osm_id;    

-- places with label tag inside geometry
UPDATE osm_polygon p
	SET linked_osm_id = n.osm_id 
	FROM osm_point  n, osm_polygon r WHERE n.name = r.name AND ST_WITHIN(n.geometry,r.geometry)
	AND p.osm_id = r.osm_id      
	AND r.osm_id NOT IN (
	SELECT osm_id 
	FROM osm_relation
	WHERE role = 'label');  

--tag linked places
UPDATE osm_point p SET linked = TRUE
	FROM osm_point po WHERE po.osm_id IN (SELECT linked_osm_id FROM osm_polygon WHERE linked_osm_id IS NOT NULL)
	AND po.osm_id = p.osm_id;


--determine parents
UPDATE osm_polygon SET parent_id = determineParentPlace(id, partition, rank_search, geometry);
UPDATE osm_point SET parent_id = determineParentPlace(id, partition, rank_search, geometry) WHERE linked IS FALSE;
SELECT determineRoadHierarchyForEachCountry();

-- create index for faster processing
CREATE INDEX IF NOT EXISTS idx_linestring_name_parent ON osm_linestring (name,parent_id);

-- prepare stats
DROP TABLE IF EXISTS sumOfQueries;
SELECT count(*) AS counter INTO sumOfQueries FROM
(SELECT DISTINCT parent_id FROM osm_linestring WHERE parent_id IS NOT NULL) AS qq ;

-- merge streets with the same name that share same points with same parent_id
SELECT count(*) AS mergedParents FROM
(SELECT mergeStreetsOfParentId(q.parent_id, row_number() OVER(), qq.counter )
FROM (SELECT DISTINCT parent_id FROM osm_linestring WHERE parent_id IS NOT NULL) AS q,
 sumOfQueries AS qq) AS qqq;

--determine parents
/*
UPDATE osm_polygon
  SET parent_ids = calculated_parent_ids
FROM (SELECT pl.id as currentID, array_agg(area.id ORDER BY area.rank_search DESC) as calculated_parent_ids
FROM osm_polygon area, osm_polygon pl 
WHERE ST_Contains(area.geometry, pl.geometry) 
GROUP BY pl.id
ORDER BY pl.id) AS spatialQuery 
WHERE osm_polygon.id = currentID;

UPDATE osm_point
  SET parent_ids = calculated_parent_ids
FROM (SELECT pl.id as currentID, array_agg(area.id ORDER BY area.rank_search DESC) as calculated_parent_ids
FROM osm_polygon area, osm_point pl 
WHERE ST_Contains(area.geometry, pl.geometry) 
GROUP BY pl.id
ORDER BY pl.id) AS spatialQuery 
WHERE osm_point.id = currentID;

UPDATE osm_linestring
  SET parent_ids = calculated_parent_ids
FROM (SELECT pl.id as currentID, array_agg(area.id ORDER BY area.rank_search DESC) as calculated_parent_ids
FROM osm_polygon area, osm_linestring pl 
WHERE ST_Contains(area.geometry, pl.geometry) 
GROUP BY pl.id
ORDER BY pl.id) AS spatialQuery 
WHERE osm_linestring.id = currentID;
*/

