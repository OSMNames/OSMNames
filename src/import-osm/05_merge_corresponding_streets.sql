/*
-- prepare stats
DROP TABLE IF EXISTS sumOfQueries;
SELECT count(*) AS counter INTO sumOfQueries FROM
(SELECT DISTINCT parent_id FROM osm_linestring WHERE parent_id IS NOT NULL) AS qq ;

-- merge streets with the same name that share same points with same parent_id
SELECT count(*) AS mergedParents FROM
(SELECT mergeStreetsOfParentId(q.parent_id, row_number() OVER(), qq.counter )
FROM (SELECT DISTINCT parent_id FROM osm_linestring WHERE parent_id IS NOT NULL) AS q,
 sumOfQueries AS qq) AS qqq;

*/

SELECT mergeStreetsOfParentId(q.parent_id)
FROM (SELECT DISTINCT parent_id FROM osm_linestring WHERE parent_id IS NOT NULL) AS q;

CREATE INDEX IF NOT EXISTS idx_osm_linestring_merged ON osm_linestring (merged);

CREATE INDEX IF NOT EXISTS idx_wikipedia_article_language_title ON wikipedia_article (language,title);
