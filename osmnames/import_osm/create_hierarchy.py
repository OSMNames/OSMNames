import os

from osmnames.database.functions import exec_sql, exec_sql_from_file, vacuum_database
from osmnames import consistency_check
from osmnames import logger

SQL_DIR = "{}/create_hierarchy/".format(os.path.dirname(__file__))
log = logger.setup(__name__)


def create_hierarchy():
    set_linestring_centers()
    cluster_geometries()

    set_parent_id_for_elements_covered_by_single_polygon()
    set_parent_id_for_polygons_intersecting_multiple_polygons()

    drop_linestring_center_index()
    consistency_check.missing_parent_ids()


def set_linestring_centers():
    exec_sql_from_file("set_linestring_centers.sql", cwd=SQL_DIR)
    vacuum_database()


def cluster_geometries():
    exec_sql("""
        CLUSTER osm_linestring_center_geom ON osm_linestring;
        CLUSTER osm_polygon_geom ON osm_polygon;
        CLUSTER osm_housenumber_geom ON osm_housenumber;
        CLUSTER osm_point_geom ON osm_point;
    """)


def set_parent_id_for_elements_covered_by_single_polygon():
    exec_sql_from_file("set_parent_id_for_elements_covered_by_single_polygon.sql", cwd=SQL_DIR)
    vacuum_database()


def set_parent_id_for_polygons_intersecting_multiple_polygons():
    exec_sql_from_file("set_parent_id_for_polygons_intersecting_multiple_polygons.sql", cwd=SQL_DIR)
    vacuum_database()


def drop_linestring_center_index():
    exec_sql("DROP INDEX osm_linestring_center_geom")
