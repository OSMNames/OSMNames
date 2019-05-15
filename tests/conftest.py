import pytest
import os
import warnings

from geoalchemy2 import Geometry # NOQA
from sqlalchemy.orm.session import Session
from sqlalchemy import exc as sa_exc

from osmnames.init_database.init_database import init_database
from osmnames.database import connection
from osmnames.database.tables import Tables
from osmnames.database.functions import exec_sql, exec_sql_from_file, wait_for_database
from osmnames.export_osmnames import export_osmnames
from osmnames.prepare_data import prepare_data

warnings.simplefilter("ignore", category=sa_exc.SAWarning)


@pytest.fixture(scope="module")
def engine():
    wait_for_database()
    _init_and_clear_database()

    yield connection.engine

    connection.engine.dispose()


@pytest.fixture(scope="function")
def session(engine):
    session = Session(engine)

    yield session

    session.close()

    exec_sql("SELECT truncate_tables('osm_test')")


@pytest.fixture(scope="module")
def tables(engine):
    return Tables(engine)


def _init_and_clear_database():
    # creates database if necessary
    init_database()

    exec_sql("DROP OWNED BY osm_test")

    # prepare schema for tests
    current_directory = os.path.dirname(os.path.realpath(__file__))
    exec_sql_from_file('helpers/schema.sql.dump', cwd=current_directory)
    exec_sql_from_file('helpers/functions.sql', cwd=current_directory)
    prepare_data.create_helper_functions()
    export_osmnames.create_functions()

    # necessary for export tests
    if not os.path.exists('/tmp/osmnames/export/'):
        os.makedirs('/tmp/osmnames/export/')
