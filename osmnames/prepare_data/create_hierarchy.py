import os

from osmnames.database.functions import exec_sql, exec_sql_from_file, vacuum_database
from osmnames import consistency_check
from osmnames import logger
from osmnames.helpers import run_in_parallel


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
    exec_sql_from_file("set_geometry_centers.sql", cwd=SQL_DIR, parallelize=True)
    vacuum_database()


def create_geometry_indexes():
    exec_sql_from_file("create_geometry_indexes.sql", cwd=SQL_DIR, parallelize=True)


def cluster_geometries():
    exec_sql_from_file("cluster_geometries.sql", cwd=SQL_DIR, parallelize=True)
    vacuum_database()


def create_parent_polygons():
    exec_sql_from_file("create_parent_polygons.sql", cwd=SQL_DIR)


def drop_parent_polygons():
    exec_sql("DROP TABLE parent_polygons CASCADE")


def set_parent_ids():
    create_parent_polygons()

    run_in_parallel(
        set_polygons_parent_ids,
        set_points_parent_ids,
        set_linestrings_parent_ids,
        set_housenumbers_parent_ids
    )

    drop_parent_polygons()
    vacuum_database()


def set_polygons_parent_ids():
    exec_sql_from_file("set_polygons_parent_ids.sql", cwd=SQL_DIR)


def set_points_parent_ids():
    exec_sql_from_file("set_points_parent_ids.sql", cwd=SQL_DIR)


def set_linestrings_parent_ids():
    exec_sql_from_file("set_linestrings_parent_ids.sql", cwd=SQL_DIR)


def set_housenumbers_parent_ids():
    exec_sql_from_file("set_housenumbers_parent_ids.sql", cwd=SQL_DIR)


def drop_geometry_center_indexes():
    exec_sql("""
        DROP INDEX osm_linestring_geometry_center;
        DROP INDEX osm_housenumber_geometry_center;
    """)
