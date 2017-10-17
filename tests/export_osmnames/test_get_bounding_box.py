import os
import pytest

from osmnames.database.functions import exec_sql_from_file
from osmnames.export_osmnames.export_osmnames import create_functions


@pytest.fixture(scope="function")
def schema(engine):
    current_directory = os.path.dirname(os.path.realpath(__file__))
    exec_sql_from_file('fixtures/test_export_osmnames.sql.dump', cwd=current_directory)
    create_functions()


def test_get_bounding_box(session, schema, tables):
    geometry_switzerland = """POLYGON((663009.012524866 5801584.86199727,953786.907618496
                            6075049.14132019,1167669.27353812 5931925.52282563,1003885.85590161
                            5751249.46091655,663009.012524866 5801584.86199727))"""

    bounding_box_switzerland = get_bounding_box(session, geometry_switzerland, "ch", 2)

    assert bounding_box_switzerland == [5.9559113,
                                        45.8181130,
                                        10.4893516,
                                        47.8084648]


def test_bbox_for_countries_with_colonies(session, schema, tables):
    bounding_box_fr = get_bounding_box(session, "POLYGON((0 0,5 0,5 5,0 5,0 0))", "fr", 2)
    assert bounding_box_fr == [-5.225, 41.333, 9.55, 51.2]

    bounding_box_nl = get_bounding_box(session, "POLYGON((0 0,5 0,5 5,0 5,0 0))", "nl", 2)
    assert bounding_box_nl == [3.133, 50.75, 7.217, 53.683]


def test_bbox_for_polygon_crossing_dateline(session, schema, tables):
    geometry_new_zealand = """MULTIPOLYGON(((18494464.2739796 -5765490.1114168,19469739.2751992
                            -4955491.9787282,19204739.6279404 -4065136.81803059,19900995.6639275
                            -4516506.15533551,18494464.2739796 -5765490.1114168)))"""

    bbox_new_zealand = get_bounding_box(session, geometry_new_zealand, "nz", 2)

    assert bbox_new_zealand == [166.1385993,
                                -45.9071982,
                                178.7736857,
                                -34.2701671]


def test_bbox_for_brazil(session, schema, tables):
    # SELECT st_astext(st_simplify(geometry, 100000)) FROM osm_polygon WHERE osm_id = -59470;
    geometry_brazil = """MULTIPOLYGON(((-8235756.84786684 -841190.874919642,-6703496.97807383 589079.881640186,-3851602.21902411
                         -793669.585571994,-5920091.83157294 -4011212.81087996,-8235756.84786684 -841190.874919642)))"""

    bbox_brazil = get_bounding_box(session, geometry_brazil, "br", 2)

    assert bbox_brazil == [-73.9830625,
                           -33.8689056,
                           -34.5995314,
                           5.2842872]


def test_bbox_for_falkland_islands(session, schema, tables):
    # SELECT st_astext(st_simplify(geometry, 100000)) FROM osm_polygon WHERE osm_id = -2185374;
    geometry_falkland_island = """MULTIPOLYGON(((-6876502.97291447 -6619095.9618266,-6439638.44644622
      -6651658.66806542,-6387351.76814869 -6752035.30436411,-6544170.5147295 -6916410.57664787,-6760580.27584192
      -6882454.668139,-6861295.56860645 -6786432.95551777,-6876502.97291447 -6619095.9618266)))"""

    bbox_falkland_island = get_bounding_box(session, geometry_falkland_island, "fk", 2)

    assert bbox_falkland_island == [-61.7726772,
                                    -52.6385132,
                                    -57.3785572,
                                    -50.9875738]


def get_bounding_box(session, geometry, country_code, admin_level):
    query = """SELECT get_bounding_box(
                    ST_SetSRID('{}'::GEOMETRY, 3857),
                    '{}'
                    ,{})""".format(geometry, country_code, admin_level)

    bounding_box = [float(session.execute(query).fetchone()[0][x]) for x in range(4)]
    return bounding_box
