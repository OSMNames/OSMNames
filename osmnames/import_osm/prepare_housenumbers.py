import os

from osmnames.helpers.database import exec_sql_from_file


def prepare_housenumbers():
    set_street_names_by_relations()
    set_street_ids()


def set_street_names_by_relations():
    exec_sql_from_file("set_housenumber_street_names_by_relations.sql", cwd=os.path.dirname(__file__))


def set_street_ids():
    exec_sql_from_file("set_housenumber_street_ids.sql", cwd=os.path.dirname(__file__))
