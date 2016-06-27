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

--create indexes
CREATE INDEX IF NOT EXISTS idx_osm_polygon_partition_rank ON osm_polygon (partition,rank_search);