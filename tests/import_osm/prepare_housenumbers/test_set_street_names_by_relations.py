import os
import pytest

from osmnames.helpers.database import exec_sql_from_file
from osmnames.import_osm.prepare_housenumbers import set_street_names_by_relations
from helpers.database import Tables


@pytest.fixture(scope="function")
def schema(engine):
    current_directory = os.path.dirname(os.path.realpath(__file__))
    exec_sql_from_file('../fixtures/test_prepare_housenumbers.sql.dump', cwd=current_directory)


@pytest.fixture(scope="function")
def tables(engine):
    return Tables(engine)


def test_when_street_relation_exists(session, schema, tables):
    session.add(tables.osm_housenumber(id=1, osm_id=1))
    session.add(tables.osm_relation(osm_id=-1, type="street", name="Oberfeldring"))
    session.add(tables.osm_relation_member(osm_id=-1, member_id=1))

    session.commit()

    set_street_names_by_relations()

    assert str(session.query(tables.osm_housenumber).get(1).street) == "Oberfeldring"


def test_when_associatedStreet_relation_exists(session, schema, tables):
    session.add(tables.osm_housenumber(id=1, osm_id=1))
    session.add(tables.osm_relation(osm_id=-1, type="associatedStreet", name="Bahnhofstrasse"))
    session.add(tables.osm_relation_member(osm_id=-1, member_id=1))

    session.commit()

    set_street_names_by_relations()

    assert str(session.query(tables.osm_housenumber).get(1).street) == "Bahnhofstrasse"
