import os

from osmnames.database.functions import exec_sql, exec_sql_from_file, vacuum_database
from osmnames.prepare_data.set_names import set_names
from osmnames.prepare_data.prepare_housenumbers import prepare_housenumbers
from osmnames.prepare_data.create_hierarchy import create_hierarchy
from osmnames import consistency_check


def prepare_data():
    configure_for_preparation()
    merge_linked_nodes()
    set_names()
    delete_unusable_entries()
    follow_wikipedia_redirects()
    set_place_ranks()
    set_country_codes()
    set_polygon_types()
    create_hierarchy()
    merge_corresponding_linestrings()
    prepare_housenumbers()


def configure_for_preparation():
    drop_unused_indexes()
    create_custom_columns()
    set_tables_unlogged()
    create_helper_functions()


def drop_unused_indexes():
    for index in ["osm_linestring_osm_id_idx", "osm_housenumber_osm_id_idx"]:
        exec_sql("DROP INDEX IF EXISTS {}".format(index))


def create_custom_columns():
    exec_sql_from_file("create_custom_columns.sql", cwd=os.path.dirname(__file__))


def set_tables_unlogged():
    exec_sql_from_file("set_tables_unlogged.sql", cwd=os.path.dirname(__file__), parallelize=True)


def create_helper_functions():
    exec_sql_from_file("create_helper_functions.sql", cwd=os.path.dirname(__file__), parallelize=True)


def merge_linked_nodes():
    exec_sql_from_file("merge_linked_nodes/merge_nodes_linked_by_relation.sql", cwd=os.path.dirname(__file__))
    vacuum_database()


def delete_unusable_entries():
    exec_sql_from_file("delete_unusable_entries.sql", cwd=os.path.dirname(__file__), parallelize=True)
    vacuum_database()


def set_place_ranks():
    exec_sql_from_file("set_place_ranks.sql", cwd=os.path.dirname(__file__))
    vacuum_database()


def set_country_codes():
    exec_sql_from_file("set_country_codes.sql", cwd=os.path.dirname(__file__))
    vacuum_database()
    consistency_check.missing_country_codes()


def set_polygon_types():
    exec_sql_from_file("set_polygon_types.sql", cwd=os.path.dirname(__file__))
    vacuum_database()


def merge_corresponding_linestrings():
    exec_sql_from_file("merge_corresponding_linestrings.sql", cwd=os.path.dirname(__file__), parallelize=True)
    vacuum_database()


def follow_wikipedia_redirects():
    exec_sql_from_file("follow_wikipedia_redirects.sql", cwd=os.path.dirname(__file__))
    vacuum_database()
