import os

from osmnames.database.functions import exec_sql, exec_sql_from_file, vacuum_database
from osmnames import consistency_check

SQL_DIR = "{}/create_hierarchy/".format(os.path.dirname(__file__))


def create_hierarchy():
    cluster_geoms()
    create_indexes()
    set_parent_id_for_elements_covered_by_single_polygon()
    set_parent_id_for_polygons_intersecting_multiple_polygons()
    set_parent_id_for_linestrings_intersecting_multiple_polygons()
    consistency_check.missing_parent_ids()


def cluster_geoms():
    exec_sql("""
        CLUSTER osm_linestring_geom ON osm_linestring;
        CLUSTER osm_polygon_geom ON osm_polygon;
        CLUSTER osm_housenumber_geom ON osm_housenumber;
        CLUSTER osm_point_geom ON osm_point;
    """)


def create_indexes():
    exec_sql("""
        CREATE INDEX IF NOT EXISTS idx_osm_polygon_place_rank ON osm_polygon(place_rank);
        CREATE INDEX IF NOT EXISTS idx_osm_polygon_type
            ON osm_polygon(type)
            WHERE type NOT IN ('water', 'desert', 'bay', 'reservoir');
    """)


def set_parent_id_for_elements_covered_by_single_polygon():
    exec_sql_from_file("set_parent_id_for_elements_covered_by_single_polygon.sql", cwd=SQL_DIR)
    vacuum_database()


def set_parent_id_for_polygons_intersecting_multiple_polygons():
    exec_sql_from_file("set_parent_id_for_polygons_intersecting_multiple_polygons.sql", cwd=SQL_DIR)
    vacuum_database()


def set_parent_id_for_linestrings_intersecting_multiple_polygons():
    exec_sql_from_file("set_parent_id_for_linestrings_intersecting_multiple_polygons.sql", cwd=SQL_DIR)
    vacuum_database()
