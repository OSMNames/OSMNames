import pytest
import os

from geoalchemy2.elements import WKTElement
from osmnames.database.functions import exec_sql_from_file
from osmnames.import_osm.import_osm import set_country_codes


@pytest.fixture(scope="function")
def schema(engine):
    current_directory = os.path.dirname(os.path.realpath(__file__))
    exec_sql_from_file('fixtures/test_prepare_imported_data.sql.dump', cwd=current_directory)


def test_osm_polygon_country_code_get_set_base_on_country_grid(session, schema, tables):
    session.add(
            tables.country_osm_grid(
                country_code='CH',
                geometry=WKTElement("POLYGON((0 0,4 0,4 4,0 4,0 0))", srid=3857)
            )
        )

    session.add(
            tables.osm_polygon(
                id=1,
                name="Some Polygon with missing country_code",
                geometry=WKTElement("POLYGON((1 1, 2 1, 2 2, 1 2,1 1))", srid=3857)
            )
        )

    session.commit()

    set_country_codes()

    assert session.query(tables.osm_polygon).get(1).country_code == 'ch'


def test_osm_polygon_country_code_get_set_bases_on_imported_country_code(session, schema, tables):
    session.add(
            tables.osm_polygon(
                id=1,
                imported_country_code='CH',
            )
        )

    session.commit()

    set_country_codes()

    assert session.query(tables.osm_polygon).get(1).country_code == 'ch'


def test_osm_polygon_country_code_get_set_with_most_intersecting_country(session, schema, tables):
    session.add(
            tables.country_osm_grid(
                country_code='CH',
                geometry=WKTElement("POLYGON((0 0,4 0,4 1,0 1,0 0))", srid=3857)
            )
        )

    session.add(
            tables.country_osm_grid(
                country_code='DE',
                geometry=WKTElement("POLYGON((0 0,4 0,4 4,0 4,0 0))", srid=3857)
            )
        )

    session.add(
            tables.osm_polygon(
                id=1,
                name="Some country with missing country_code",
                place_rank=4,
                geometry=WKTElement("POLYGON((0 0,4 0,4 4,0 4,0 0))", srid=3857)
            )
        )

    session.commit()

    set_country_codes()

    assert session.query(tables.osm_polygon).get(1).country_code == 'de'
