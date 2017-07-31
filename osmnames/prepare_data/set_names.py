import os

from osmnames.database.functions import exec_sql_from_file, vacuum_database

SQL_DIR = "{}/set_names/".format(os.path.dirname(__file__))


def set_names():
    set_names_from_tags()
    set_linestring_names_from_relations()
    vacuum_database()


def set_names_from_tags():
    exec_sql_from_file("set_names_from_tags.sql", cwd=SQL_DIR)


def set_linestring_names_from_relations():
    exec_sql_from_file("set_linestring_names_from_relations.sql", cwd=SQL_DIR)
