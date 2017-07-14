import os

from osmnames.database.functions import exec_sql_from_file
from osmnames import consistency_check

SQL_DIR = "{}/prepare_housenumbers/".format(os.path.dirname(__file__))


def prepare_housenumbers():
    set_street_names()
    set_street_ids()


def set_street_names():
    set_street_attributes_by_street_relation_members()
    set_street_names_by_relation_attributes()
    consistency_check.missing_street_names()


def set_street_attributes_by_street_relation_members():
    exec_sql_from_file("set_street_attributes_by_street_relation_members.sql", cwd=SQL_DIR)


def set_street_names_by_relation_attributes():
    exec_sql_from_file("set_street_names_by_relation_attributes.sql", cwd=SQL_DIR)


def set_street_ids():
    exec_sql_from_file("set_street_ids.sql", cwd=SQL_DIR)
    consistency_check.missing_street_ids()
