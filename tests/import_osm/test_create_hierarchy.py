import pytest
import os

from geoalchemy2.elements import WKTElement
from osmnames.database.functions import exec_sql_from_file
from osmnames.import_osm.import_osm import create_hierarchy


@pytest.fixture(scope="function")
def schema(engine):
    current_directory = os.path.dirname(os.path.realpath(__file__))
    exec_sql_from_file('fixtures/test_prepare_imported_data.sql.dump', cwd=current_directory)


def test_osm_polygon_parent_id_get_set_if_covered(session, schema, tables):
    session.add(
            tables.osm_polygon(
                id=1,
                name="Some Polygon with missing parent",
                admin_level=16,
                country_code='ch',
                type='city',
                geometry=WKTElement("POLYGON((1 1, 2 1, 2 2, 1 2,1 1))", srid=3857)
            )
        )

    session.add(
            tables.osm_polygon(
                id=2,
                name="Some Polygon covering the other polygon",
                place_rank=22,
                admin_level=12,
                country_code='ch',
                type='country',
                geometry=WKTElement("POLYGON((0 0,4 0,4 4,0 4,0 0))", srid=3857)
            )
        )

    session.commit()

    create_hierarchy()

    assert session.query(tables.osm_polygon).get(1).parent_id == 2


def test_osm_polygon_parent_id_get_set_with_nearest_rank(session, schema, tables):
    session.add(
            tables.osm_polygon(
                id=1,
                name="Some Polygon with missing parent",
                place_rank=22,
                admin_level=16,
                country_code='ch',
                type='city',
                geometry=WKTElement("POLYGON((1 1, 2 1, 2 2, 1 2,1 1))", srid=3857)
            )
        )

    session.add(
            tables.osm_polygon(
                id=2,
                name="Some Polygon with lower rank covering the other polygon",
                place_rank=24,
                admin_level=12,
                country_code='ch',
                type='continent',
                geometry=WKTElement("POLYGON((0 0,4 0,4 4,0 4,0 0))", srid=3857)
            )
        )

    session.add(
            tables.osm_polygon(
                id=3,
                name="Some Polygon with same rank covering the other polygon",
                place_rank=22,
                admin_level=12,
                country_code='ch',
                type='country',
                geometry=WKTElement("POLYGON((0 0,4 0,4 4,0 4,0 0))", srid=3857)
            )
        )

    session.commit()

    create_hierarchy()

    assert session.query(tables.osm_polygon).get(1).parent_id == 3


def test_osm_polygon_parent_id_get_NOT_set_if_admin_level_is_lower(session, schema, tables):
    session.add(
            tables.osm_polygon(
                id=1,
                name="Some Polygon with missing parent",
                admin_level=12,
                country_code='ch',
                type='city',
                geometry=WKTElement("POLYGON((1 1, 2 1, 2 2, 1 2,1 1))", srid=3857)
            )
        )

    session.add(
            tables.osm_polygon(
                id=2,
                name="Some Polygon covering the other polygon",
                place_rank=22,
                admin_level=16,
                country_code='ch',
                type='country',
                geometry=WKTElement("POLYGON((0 0,4 0,4 4,0 4,0 0))", srid=3857)
            )
        )

    session.commit()

    create_hierarchy()

    assert session.query(tables.osm_polygon).get(1).parent_id is None


def test_osm_polygon_parent_id_get_set_if_admin_level_not_provided(session, schema, tables):
    session.add(
            tables.osm_polygon(
                id=1,
                name="Some Polygon with missing parent and admin_level",
                country_code='ch',
                type='city',
                geometry=WKTElement("POLYGON((1 1, 2 1, 2 2, 1 2,1 1))", srid=3857)
            )
        )

    session.add(
            tables.osm_polygon(
                id=2,
                name="Some Polygon covering the other polygon",
                place_rank=22,
                admin_level=8,
                country_code='ch',
                type='country',
                geometry=WKTElement("POLYGON((0 0,4 0,4 4,0 4,0 0))", srid=3857)
            )
        )

    session.commit()

    create_hierarchy()

    assert session.query(tables.osm_polygon).get(1).parent_id == 2


# issue https://github.com/OSMNames/OSMNames/issues/79
def test_osm_linestring_parent_id_get_set_with_most_overlapping_polygon(session, schema, tables):
    session.add(
            tables.osm_linestring(
                id=1,
                osm_id=25650226,
                name="Bietinger Weg (which crosses a border)",
                country_code='ch',
                geometry=WKTElement("""LINESTRING(964325.504274035
                    6058403.91909057,964772.621700702 6058357.62003331)""", srid=3857)
            )
        )

    session.add(
            tables.osm_polygon(
                id=2,
                osm_id=-1683703,
                name="Schaffhausen",
                place_rank=22,
                admin_level=16,
                country_code='ch',
                type='country',
                geometry=WKTElement("""POLYGON((950780.204111859 6063212.30455326,969117.169147176
                    6060704.86141201,964374.807650203 6054659.28237665,950780.204111859
                    6063212.30455326))""", srid=3857)
            )
        )

    session.add(
            tables.osm_polygon(
                id=3,
                osm_id=-2785126,
                name="Buesingen am Hochrhein",
                place_rank=22,
                admin_level=16,
                country_code='ch',
                type='country',
                geometry=WKTElement("""POLYGON((963869.951901861 6055659.0183817,965841.14454867
                    6056686.91594208,964544.74754235 6059302.14781332,968620.916296797
                    6059604.16227536,970467.245624132 6055551.35469413,963869.951901861
                    6055659.0183817))""", srid=3857)
            )
        )

    session.commit()

    create_hierarchy()

    assert session.query(tables.osm_linestring).get(1).parent_id == 2


def test_most_overlapping_polygon_ignored_if_admin_level_lower(session, schema, tables):
    session.add(
            tables.osm_polygon(
                id=1,
                name="Polygon with low admin_level",
                country_code='ch',
                admin_level=4,
                geometry=WKTElement("""LINESTRING(964325.504274035
                    6058403.91909057,964772.621700702 6058357.62003331)""", srid=3857)
            )
        )

    session.add(
            tables.osm_polygon(
                id=2,
                name="Overlapping Polygon with high admin_level",
                place_rank=22,
                admin_level=8,
                geometry=WKTElement("""POLYGON((950780.204111859 6063212.30455326,969117.169147176
                    6060704.86141201,964374.807650203 6054659.28237665,950780.204111859
                    6063212.30455326))""", srid=3857)
            )
        )

    session.commit()

    create_hierarchy()

    assert session.query(tables.osm_polygon).get(1).parent_id is None
