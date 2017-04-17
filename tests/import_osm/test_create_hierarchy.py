import pytest
import os

from geoalchemy2.elements import WKTElement
from osmnames.helpers.database import exec_sql_from_file
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
                geometry=WKTElement("POLYGON((0 0,4 0,4 4,0 4,0 0))", srid=3857)
            )
        )

    session.commit()

    create_hierarchy()

    assert session.query(tables.osm_polygon).get(1).parent_id is None
