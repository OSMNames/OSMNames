import pytest
import os

from osmnames.database.functions import exec_sql_from_file
from osmnames.export_osmnames.export_osmnames import create_functions


@pytest.fixture(scope="function")
def schema(engine):
    current_directory = os.path.dirname(os.path.realpath(__file__))
    exec_sql_from_file('fixtures/test_export_osmnames.sql.dump', cwd=current_directory)
    create_functions()


def test_get_housenumbers_if_one_exists(session, schema, tables):
    session.add(tables.osm_housenumber(street_id=1337, housenumber="12"))

    session.commit()

    assert get_housenumbers(session, 1337) == "12"


def test_get_housenumbers_if_multiple_exists(session, schema, tables):
    session.add(tables.osm_housenumber(street_id=1337, housenumber="12"))
    session.add(tables.osm_housenumber(street_id=1337, housenumber="13"))

    session.commit()

    assert get_housenumbers(session, 1337) == "12, 13"


def test_get_housenumbers_if_others_exists(session, schema, tables):
    session.add(tables.osm_housenumber(street_id=42, housenumber="12"))

    session.commit()

    assert get_housenumbers(session, 1337) is None


def test_get_housenumbers_if_no_exists(session, schema, tables):
    assert get_housenumbers(session, 1337) is None


def get_housenumbers(session, osm_id):
    query = "SELECT get_housenumbers('{}')".format(osm_id)
    return session.execute(query).fetchone()[0]
