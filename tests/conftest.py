import pytest

from sqlalchemy.engine import create_engine
from sqlalchemy.orm.session import Session

@pytest.fixture(scope="module")
def engine():
    return create_engine('postgresql:///osm')

@pytest.fixture(scope="module")
def connection(engine):
    print("init connection")
    connection = engine.connect()
    transaction = connection.begin()

    yield connection

    print("teardown connection")
    transaction.rollback()
    connection.close()
    engine.dispose()

@pytest.fixture(scope="function")
def session(request, connection):
    print("init session")
    __transaction = connection.begin_nested()
    session = Session(connection)

    yield session

    print("teardown session")
    session.close()
    __transaction.rollback()
