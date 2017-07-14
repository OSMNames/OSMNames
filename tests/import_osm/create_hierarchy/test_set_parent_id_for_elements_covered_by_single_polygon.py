import pytest
import os

from geoalchemy2.elements import WKTElement
from osmnames.database.functions import exec_sql_from_file
from osmnames.import_osm.create_hierarchy import set_parent_id_for_elements_covered_by_single_polygon


@pytest.fixture(scope="function")
def schema(engine):
    current_directory = os.path.dirname(os.path.realpath(__file__))
    exec_sql_from_file('../fixtures/test_prepare_imported_data.sql.dump', cwd=current_directory)


def test_osm_polygon_parent_id_get_set_if_covered(session, schema, tables):
    session.add(
            tables.osm_polygon(
                id=1,
                name="Some Polygon with missing parent",
                place_rank=16,
                type='city',
                geometry=WKTElement("POLYGON((1 1, 2 1, 2 2, 1 2,1 1))", srid=3857)
            )
        )

    session.add(
            tables.osm_polygon(
                id=2,
                name="Some Polygon covering the other polygon",
                place_rank=4,
                type='country',
                geometry=WKTElement("POLYGON((0 0,4 0,4 4,0 4,0 0))", srid=3857)
            )
        )

    session.commit()

    set_parent_id_for_elements_covered_by_single_polygon()

    assert session.query(tables.osm_polygon).get(1).parent_id == 2


def test_osm_polygon_parent_id_get_set_with_nearest_rank(session, schema, tables):
    session.add(
            tables.osm_polygon(
                id=1,
                name="Some Polygon with missing parent",
                place_rank=20,
                type='city',
                geometry=WKTElement("POLYGON((1 1, 2 1, 2 2, 1 2,1 1))", srid=3857)
            )
        )

    session.add(
            tables.osm_polygon(
                id=2,
                name="Some Polygon with higher rank, covering the other polygon",
                place_rank=8,
                type='continent',
                geometry=WKTElement("POLYGON((0 0,4 0,4 4,0 4,0 0))", srid=3857)
            )
        )

    session.add(
            tables.osm_polygon(
                id=3,
                name="Some Polygon with same rank, covering the other polygon",
                place_rank=16,
                type='country',
                geometry=WKTElement("POLYGON((0 0,4 0,4 4,0 4,0 0))", srid=3857)
            )
        )

    session.commit()

    set_parent_id_for_elements_covered_by_single_polygon()

    assert session.query(tables.osm_polygon).get(1).parent_id == 3


def test_osm_polygon_parent_id_get_NOT_set_if_place_rank_is_lower(session, schema, tables):
    session.add(
            tables.osm_polygon(
                id=1,
                name="Some Polygon with missing parent",
                place_rank=12,
                type='city',
                geometry=WKTElement("POLYGON((1 1, 2 1, 2 2, 1 2,1 1))", srid=3857)
            )
        )

    session.add(
            tables.osm_polygon(
                id=2,
                name="Some Polygon covering the other polygon",
                place_rank=20,
                type='country',
                geometry=WKTElement("POLYGON((0 0,4 0,4 4,0 4,0 0))", srid=3857)
            )
        )

    session.commit()

    set_parent_id_for_elements_covered_by_single_polygon()

    assert session.query(tables.osm_polygon).get(1).parent_id is None


def test_osm_polygon_parent_id_get_set_if_place_rank_not_provided(session, schema, tables):
    session.add(
            tables.osm_polygon(
                id=1,
                name="Some Polygon with missing parent and place_rank",
                type='city',
                geometry=WKTElement("POLYGON((1 1, 2 1, 2 2, 1 2,1 1))", srid=3857)
            )
        )

    session.add(
            tables.osm_polygon(
                id=2,
                name="Some Polygon covering the other polygon",
                place_rank=20,
                type='country',
                geometry=WKTElement("POLYGON((0 0,4 0,4 4,0 4,0 0))", srid=3857)
            )
        )

    session.commit()

    set_parent_id_for_elements_covered_by_single_polygon()

    assert session.query(tables.osm_polygon).get(1).parent_id == 2


def test_linestring_parent_id_get_set_if_place_rank_larger_than_20(session, schema, tables):
    session.add(
            tables.osm_linestring(
                id=1,
                name="Some linestring with missing parent",
                type='street',
                geometry=WKTElement("LINESTRING(1 1, 2 1)", srid=3857)
            )
        )

    session.add(
            tables.osm_polygon(
                id=2,
                name="Some Polygon covering the linestring",
                place_rank=20,
                type='city',
                geometry=WKTElement("POLYGON((0 0,4 0,4 4,0 4,0 0))", srid=3857)
            )
        )

    session.commit()

    set_parent_id_for_elements_covered_by_single_polygon()

    assert session.query(tables.osm_linestring).get(1).parent_id == 2


def test_linestring_parent_id_get_NOT_set_if_place_rank_lower_than_20(session, schema, tables):
    session.add(
            tables.osm_linestring(
                id=1,
                name="Some linestring with missing parent",
                type='street',
                geometry=WKTElement("LINESTRING(1 1, 2 1)", srid=3857)
            )
        )

    session.add(
            tables.osm_polygon(
                id=2,
                name="Some Polygon covering the linestring",
                place_rank=18,
                type='country',
                geometry=WKTElement("POLYGON((0 0,4 0,4 4,0 4,0 0))", srid=3857)
            )
        )

    session.commit()

    set_parent_id_for_elements_covered_by_single_polygon()

    assert session.query(tables.osm_linestring).get(1).parent_id is None
