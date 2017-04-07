import os
import pytest

from osmnames.helpers.database import exec_sql_from_file
from osmnames.import_osm.prepare_housenumbers import set_street_ids


@pytest.fixture(scope="function")
def schema():
    current_directory = os.path.dirname(os.path.realpath(__file__))
    exec_sql_from_file('../fixtures/test_prepare_housenumbers.sql.dump', cwd=current_directory)


def test_when_street_with_same_parent_id_and_name_exists(session, schema, tables):
    session.add(tables.osm_housenumber(id=1, parent_id=1337, street="Haldenweg"))
    session.add(tables.osm_linestring(id=42, parent_id=1337, name="Haldenweg"))

    session.commit()

    set_street_ids()

    assert session.query(tables.osm_housenumber).get(1).street_id == 42


def test_when_street_with_same_parent_id_but_different_name_exists(session, schema, tables):
    session.add(tables.osm_housenumber(id=1, parent_id=1337, street="Haldenweg"))
    session.add(tables.osm_linestring(id=42, parent_id=1337, name="Hornstrasse"))

    session.commit()

    set_street_ids()

    assert session.query(tables.osm_housenumber).get(1).street_id is None


def test_when_street_with_same_name_but_different_parent_id_exists(session, schema, tables):
    session.add(tables.osm_housenumber(id=1, parent_id=1337, street="Haldenweg"))
    session.add(tables.osm_linestring(id=42, parent_id=9999, name="Haldenweg"))

    session.commit()

    set_street_ids()

    assert session.query(tables.osm_housenumber).get(1).street_id is None
