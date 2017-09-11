import os

from osmnames.database.functions import exec_sql_from_file
from osmnames import consistency_check

SQL_DIR = "{}/prepare_housenumbers/".format(os.path.dirname(__file__))


def prepare_housenumbers():
    set_street_attributes_by_street_relation_members()
    set_street_names_by_relation_attributes()
    normalize_street_names()
    set_street_ids_by_street_name()
    set_street_attributes_by_nearest_street()
    sanitize_housenumbers()
    consistency_check.missing_street_ids()


def set_street_attributes_by_street_relation_members():
    exec_sql_from_file("set_street_attributes_by_street_relation_members.sql", cwd=SQL_DIR)


def set_street_names_by_relation_attributes():
    exec_sql_from_file("set_street_names_by_relation_attributes.sql", cwd=SQL_DIR)


def normalize_street_names():
    exec_sql_from_file("normalize_street_names.sql", cwd=SQL_DIR)


def set_street_ids_by_street_name():
    exec_sql_from_file("set_street_ids_by_street_name.sql", cwd=SQL_DIR)


def set_street_attributes_by_nearest_street():
    exec_sql_from_file("set_street_attributes_by_nearest_street.sql", cwd=SQL_DIR)


def sanitize_housenumbers():
    exec_sql_from_file("sanitize_housenumbers.sql", cwd=SQL_DIR)
