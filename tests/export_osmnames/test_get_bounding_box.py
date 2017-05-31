import pytest
import os

from geoalchemy2.elements import WKTElement
from osmnames.export_osmnames.export_osmnames import create_functions

@pytest.fixture(scope="function")
def schema(engine):
    current_directory = os.path.dirname(os.path.realpath(__file__))
    create_functions()


def test_bbox_for_countries_with_colonies(session, schema, tables):

    bounding_box_fr = get_bounding_box(session, WKTElement("POLYGON((0 0,5 0,5 5,0 5,0 0))", srid=3857), "fr", 2)
    assert bounding_box_fr == [-5.225,41.333,9.55,51.2]

    bounding_box_nl = get_bounding_box(session, WKTElement("POLYGON((0 0,5 0,5 5,0 5,0 0))", srid=3857), "nl", 2)
    assert bounding_box_nl == [3.133,50.75,7.217,53.683]


def get_bounding_box(session, geometry, country_code, admin_level):

    query = "SELECT get_bounding_box('{}','{}',{})".format(geometry, country_code, admin_level)
    bounding_box = [float(session.execute(query).fetchone()[0][x]) for x in range(4)]
    return bounding_box
