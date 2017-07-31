import pytest
import os

from geoalchemy2.elements import WKTElement
from osmnames.database.functions import exec_sql_from_file
from osmnames.prepare_data.prepare_data import delete_unusable_entries


@pytest.fixture(scope="module")
def schema():
    current_directory = os.path.dirname(os.path.realpath(__file__))
    exec_sql_from_file('fixtures/test_prepare_imported_data.sql.dump', cwd=current_directory)


def test_osm_polygon_with_blank_names_get_deleted(session, schema, tables):
    session.add(tables.osm_polygon(name="gugus"))
    session.add(tables.osm_polygon(name=""))
    session.commit()

    delete_unusable_entries()

    assert session.query(tables.osm_polygon).count(), 1


def test_osm_polygon_with_null_names_get_deleted(session, schema, tables):
    session.add(tables.osm_polygon(name="gugus"))
    session.add(tables.osm_polygon())
    session.commit()

    delete_unusable_entries()

    assert session.query(tables.osm_polygon).count(), 1


def test_osm_point_with_blank_names_get_deleted(session, schema, tables):
    session.add(tables.osm_point(name="gugus"))
    session.add(tables.osm_point(name=""))
    session.commit()

    delete_unusable_entries()

    assert session.query(tables.osm_point).count(), 1


def test_osm_linestring_with_blank_names_get_deleted(session, schema, tables):
    session.add(tables.osm_linestring(name="gugus"))
    session.add(tables.osm_linestring(name=""))
    session.commit()

    delete_unusable_entries()

    assert session.query(tables.osm_linestring).count(), 1


def test_osm_polygon_with_empty_geometries_get_deleted(session, schema, tables):
    session.add(tables.osm_polygon(geometry=WKTElement('POLYGON((1 2, 3 4, 5 6, 1 2))', srid=3857)))
    session.add(tables.osm_polygon(geometry=WKTElement('POLYGON EMPTY', srid=3857)))
    session.commit()

    delete_unusable_entries()

    assert session.query(tables.osm_polygon).count(), 1
