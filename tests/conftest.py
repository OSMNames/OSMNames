import pytest

from sqlalchemy.engine import create_engine
from sqlalchemy.orm.session import Session
from geoalchemy2 import Geometry # NOQA

from osmnames import settings
from osmnames.init_database.init_database import init_database
from osmnames.helpers.database import exec_sql


@pytest.fixture(scope="module")
def engine():
    _recreate_database()

    engine = create_engine("postgresql+psycopg2://{user}:{password}@{host}/{db_name}".format(
        user=settings.get("DB_USER"),
        password=settings.get("DB_PASSWORD"),
        host=settings.get("DB_HOST"),
        db_name=settings.get("DB_NAME"),
        ))

    yield engine

    engine.dispose()


@pytest.fixture(scope="function")
def session(engine):
    session = Session(engine)

    yield session

    session.close()


def _recreate_database():
    print("drop database")
    drop_database_query = "DROP DATABASE IF EXISTS {};".format(settings.get("DB_NAME"))
    drop_user_query = "DROP USER IF EXISTS {};".format(settings.get("DB_USER"))
    exec_sql(drop_database_query, user="postgres", database="postgres")
    exec_sql(drop_user_query, user="postgres", database="postgres")

    print("create database")
    init_database()
