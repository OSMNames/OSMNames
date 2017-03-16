import os

from subprocess import check_call
from sqlalchemy import MetaData, Table


def test_if_empty_osm_polygon_tmp_get_deleted(session, engine):
    load_sql_dump('fixtures/unusable_entries.sql.dump')

    table = Table('osm_polygon_tmp', MetaData(), autoload=True, autoload_with=engine)

    count = session.query(table).count()
    assert count == 1

    psql_exec("01_delete_unusable_entries.sql")

    count = session.query(table).count()
    assert count == 0


def load_sql_dump(path):
    current_directory = os.path.dirname(os.path.realpath(__file__))
    check_call(["psql", "-f", path], cwd=current_directory)


def psql_exec(filename):
    directory = "{1}/import-osm/".format(os.getenv('SRC_DIR'))
    check_call(["psql", "-f", "{1}/{2}".format(directory, filename)])
