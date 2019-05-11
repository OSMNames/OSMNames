import os
from osmnames.database.functions import exec_sql_from_file, vacuum_database

SQL_DIR = "{}/merge_linked_nodes/".format(os.path.dirname(__file__))


def merge_linked_nodes():
    merge_nodes_linked_by_relation()


def merge_nodes_linked_by_relation():
    exec_sql_from_file("merge_nodes_linked_by_relation.sql", cwd=SQL_DIR)
    vacuum_database()
