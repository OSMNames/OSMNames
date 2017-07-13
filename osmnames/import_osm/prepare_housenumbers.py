import os

from osmnames.database.functions import exec_sql_from_file
from osmnames import consistency_check

SQL_DIR = "{}/prepare_housenumbers/".format(os.path.dirname(__file__))


def prepare_housenumbers():
    set_street_names_by_relations()
    set_street_ids()


def set_street_names_by_relations():
    exec_sql_from_file("set_street_names_by_relations.sql", cwd=SQL_DIR)
    consistency_check.missing_street_names()


def set_street_ids():
    exec_sql_from_file("set_street_ids.sql", cwd=SQL_DIR)
    consistency_check.missing_street_ids()
