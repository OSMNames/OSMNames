import pytest

from geoalchemy2 import Geometry # NOQA
from sqlalchemy.orm.session import Session

from osmnames import settings
from osmnames.init_database.init_database import init_database
from osmnames.database import connection
from osmnames.database.tables import Tables
from osmnames.database.functions import exec_sql, wait_for_database


@pytest.fixture(scope="module")
def engine():
    wait_for_database()
    _recreate_database()

    yield connection.engine

    connection.engine.dispose()


@pytest.fixture(scope="function")
def session(engine):
    session = Session(engine)

    yield session

    session.close()


@pytest.fixture(scope="module")
def tables(engine):
    return Tables(engine)


def _recreate_database():
    print("drop database")
    drop_database_query = "DROP DATABASE IF EXISTS {};".format(settings.get("DB_NAME"))
    drop_user_query = "DROP USER IF EXISTS {};".format(settings.get("DB_USER"))
    exec_sql(drop_database_query, user="postgres", database="postgres")
    exec_sql(drop_user_query, user="postgres", database="postgres")

    print("create database")
    init_database()
