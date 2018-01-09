import os

from osmnames.database.functions import exec_sql, exec_sql_from_file, vacuum_database
from osmnames import consistency_check
from osmnames import logger

SQL_DIR = "{}/create_hierarchy/".format(os.path.dirname(__file__))
log = logger.setup(__name__)


def create_hierarchy():
    set_geometry_centers()
    create_geometry_indexes()
    cluster_geometries()

    set_parent_ids()

    drop_geometry_center_indexes()
    consistency_check.missing_parent_ids()


def set_geometry_centers():
    exec_sql_from_file("set_geometry_centers.sql", cwd=SQL_DIR)
    vacuum_database()


def create_geometry_indexes():
    exec_sql("""
      CREATE INDEX osm_linestring_geometry_center ON osm_linestring USING gist(geometry_center);
      CREATE INDEX osm_housenumber_geometry_center ON osm_housenumber USING gist(geometry_center);
      CREATE INDEX osm_polygon_geometry ON osm_polygon USING gist(geometry);
    """)


def cluster_geometries():
    exec_sql_from_file("cluster_geometries.sql", cwd=SQL_DIR)
    vacuum_database()


def set_parent_ids():
    exec_sql_from_file("set_parent_ids.sql", cwd=SQL_DIR)
    vacuum_database()


def drop_geometry_center_indexes():
    exec_sql("""
        DROP INDEX osm_linestring_geometry_center;
        DROP INDEX osm_housenumber_geometry_center;
        DROP INDEX osm_polygon_geometry;
    """)
