Indices
=======

The following indices have been applied to speed up the queries:

.. code-block:: sql

	CREATE INDEX IF NOT EXISTS idx_osm_polgyon_geom ON osm_polygon USING gist (geometry);
	CREATE INDEX IF NOT EXISTS idx_osm_point_geom ON osm_point USING gist (geometry);
	CREATE INDEX IF NOT EXISTS idx_osm_linestring_geom ON osm_linestring USING gist (geometry);

	CREATE INDEX IF NOT EXISTS idx_osm_polygon_partition_rank ON osm_polygon (partition,rank_search);
	CREATE INDEX IF NOT EXISTS idx_osm_polygon_id ON osm_polygon (id);

	CREATE INDEX IF NOT EXISTS idx_osm_point_osm_id ON osm_point (osm_id);

	CREATE INDEX IF NOT EXISTS idx_osm_linestring_merged_false ON osm_linestring (merged) WHERE merged IS FALSE;

Most noteworthy is the creation of geometry GIST indices for the geometry tables. This speeds up spatial queries tremendously.
