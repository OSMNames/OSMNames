import pytest
import os

from geoalchemy2.elements import WKTElement
from osmnames.helpers.database import exec_sql_from_file
from osmnames.import_osm.import_osm import create_hierarchy, create_functions
from helpers.database import table_class_for


@pytest.fixture(scope="function")
def schema(engine):
    current_directory = os.path.dirname(os.path.realpath(__file__))
    exec_sql_from_file('fixtures/test_create_hierarchy_schema.sql.dump', cwd=current_directory)
    create_functions()


def test_osm_polygon_parent_id_get_set_if_covered(engine, session, schema):
    """ test if parent_id of polygon is set if there is a different polygon, which covers it """

    osm_polygon = table_class_for("osm_polygon", engine)

    session.add(
            osm_polygon(id=1,
                        name="Some Polygon with missing parent",
                        rank_search=30,
                        partition=10,
                        geometry=WKTElement("POLYGON((1 1, 2 1, 2 2, 1 2,1 1))", srid=3857)
                        )
            )

    session.add(
            osm_polygon(id=2,
                        name="Some Polygon covering the other polygon",
                        rank_search=25,
                        partition=10,
                        geometry=WKTElement("POLYGON((0 0,4 0,4 4,0 4,0 0))", srid=3857)
                        )
            )

    session.commit()

    create_hierarchy()

    assert session.query(osm_polygon).get(1).parent_id == 2


def test_osm_polygon_parent_id_get_set_with_nearest_rank(engine, session, schema):
    osm_polygon = table_class_for("osm_polygon", engine)

    session.add(
            osm_polygon(id=1,
                        name="Some Polygon with missing parent",
                        rank_search=30,
                        partition=10,
                        geometry=WKTElement("POLYGON((1 1, 2 1, 2 2, 1 2,1 1))", srid=3857)
                        )
            )

    session.add(
            osm_polygon(id=2,
                        name="Some Polygon with lower rank covering the other polygon",
                        rank_search=26,
                        partition=10,
                        geometry=WKTElement("POLYGON((0 0,4 0,4 4,0 4,0 0))", srid=3857)
                        )
            )

    session.add(
            osm_polygon(id=3,
                        name="Some Polygon with same rank covering the other polygon",
                        rank_search=30,
                        partition=10,
                        geometry=WKTElement("POLYGON((0 0,4 0,4 4,0 4,0 0))", srid=3857)
                        )
            )

    session.commit()

    create_hierarchy()

    assert session.query(osm_polygon).get(1).parent_id == 3


def test_osm_polygon_parent_id_get_NOT_set_if_rank_is_higher(engine, session, schema):
    """ do not set the parent_id if the covering polygon has a higher rank """

    osm_polygon = table_class_for("osm_polygon", engine)

    session.add(
            osm_polygon(id=1,
                        name="Some Polygon with missing parent",
                        rank_search=30,
                        partition=10,
                        geometry=WKTElement("POLYGON((1 1, 2 1, 2 2, 1 2,1 1))", srid=3857)
                        )
            )

    session.add(
            osm_polygon(id=2,
                        name="Some Polygon covering the other polygon",
                        rank_search=40,
                        partition=10,
                        geometry=WKTElement("POLYGON((0 0,4 0,4 4,0 4,0 0))", srid=3857)
                        )
            )

    session.commit()

    create_hierarchy()

    assert session.query(osm_polygon).get(1).parent_id is None
