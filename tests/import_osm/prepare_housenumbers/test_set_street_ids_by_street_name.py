import os
import pytest

from geoalchemy2.elements import WKTElement
from osmnames.database.functions import exec_sql_from_file
from osmnames.import_osm.prepare_housenumbers import set_street_ids_by_street_name


housenumber_geometry = WKTElement("""POLYGON((977335.866537083 5984030.73152414,977356.851263236
                                     5984036.56047328,977357.448427519 5984021.10826761,977335.866537083
                                     5984030.73152414))""", srid=3857)

near_street_geometry = WKTElement("""LINESTRING(977437.841669201 5984049.19445902,977292.198898845
                                     5984037.12412187)""", srid=3857)


@pytest.fixture(scope="function")
def schema():
    current_directory = os.path.dirname(os.path.realpath(__file__))
    exec_sql_from_file('../fixtures/test_prepare_imported_data.sql.dump', cwd=current_directory)


def test_when_near_street_with_same_name_exists(session, schema, tables):
    session.add(tables.osm_housenumber(id=1, geometry=housenumber_geometry, normalized_street="haldenweg"))
    session.add(tables.osm_linestring(id=2, osm_id=42, geometry=near_street_geometry, normalized_name="haldenweg"))

    session.commit()

    set_street_ids_by_street_name()

    assert session.query(tables.osm_housenumber).get(1).street_id == 42


def test_when_near_street_with_different_name_exists(session, schema, tables):
    session.add(tables.osm_housenumber(id=1, geometry=housenumber_geometry, normalized_street="haldenweg"))
    session.add(tables.osm_linestring(id=2, osm_id=42, geometry=near_street_geometry, normalized_name="hornstrasse"))

    session.commit()

    set_street_ids_by_street_name()

    assert session.query(tables.osm_housenumber).get(1).street_id is None


def test_when_far_away_street_with_same_name_exists(session, schema, tables):
    far_away_street_geometry = WKTElement("""LINESTRING(978158.180417009 5981253.11872189,978262.432237961
                                             5980562.33444262)""", srid=3857)

    session.add(tables.osm_housenumber(id=1, geometry=housenumber_geometry, normalized_street="haldenweg"))
    session.add(tables.osm_linestring(id=2, osm_id=42, geometry=far_away_street_geometry, normalized_name="haldenweg"))

    session.commit()

    set_street_ids_by_street_name()

    assert session.query(tables.osm_housenumber).get(1).street_id is None


def test_when_near_merged_street_with_same_name_exists(session, schema, tables):
    session.add(tables.osm_housenumber(id=1, geometry=housenumber_geometry, normalized_street="haldenweg"))
    session.add(tables.osm_linestring(id=2, geometry=near_street_geometry, merged_into=77, normalized_name="haldenweg"))

    session.commit()

    set_street_ids_by_street_name()

    assert session.query(tables.osm_housenumber).get(1).street_id == 77


def test_when_near_street_with_almost_same_name_exists(session, schema, tables):
    session.add(tables.osm_housenumber(id=1, geometry=housenumber_geometry, normalized_street="bochslensrasse"))
    session.add(tables.osm_linestring(id=2, osm_id=2, geometry=near_street_geometry, normalized_name="bochslenstrasse"))

    session.commit()

    set_street_ids_by_street_name()

    assert session.query(tables.osm_housenumber).get(1).street_id == 2


def test_when_street_name_contains_full_housenumber_street(session, schema, tables):
    session.add(tables.osm_housenumber(id=1, geometry=housenumber_geometry, normalized_street="serre"))
    session.add(tables.osm_linestring(id=2, osm_id=42, geometry=near_street_geometry, normalized_name="ruedelaserre"))

    session.commit()

    set_street_ids_by_street_name()

    assert session.query(tables.osm_housenumber).get(1).street_id == 42


def test_when_housenumber_street_contains_full_street_name(session, schema, tables):
    session.add(tables.osm_housenumber(id=1, geometry=housenumber_geometry, normalized_street="citepreville19"))
    session.add(tables.osm_linestring(id=2, osm_id=42, geometry=near_street_geometry, normalized_name="citepreville"))

    session.commit()

    set_street_ids_by_street_name()

    assert session.query(tables.osm_housenumber).get(1).street_id == 42
