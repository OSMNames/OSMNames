import pytest
import os

from geoalchemy2.elements import WKTElement
from osmnames.helpers.database import exec_sql_from_file
from osmnames.import_osm.import_osm import set_country_codes


@pytest.fixture(scope="function")
def schema(engine):
    current_directory = os.path.dirname(os.path.realpath(__file__))
    exec_sql_from_file('fixtures/test_prepare_imported_data.sql.dump', cwd=current_directory)


def test_osm_polygon_country_code_get_set_if_covering_polygon_with_place_rank_4_exists(session, schema, tables):
    session.add(
            tables.osm_polygon(
                id=1,
                name="Some Polygon with missing country_code",
                geometry=WKTElement("POLYGON((1 1, 2 1, 2 2, 1 2,1 1))", srid=3857)
            )
        )

    session.add(
            tables.osm_polygon(
                id=2,
                name="country polygon (which has place_rank = 4)",
                place_rank=4,
                imported_country_code='CH',
                geometry=WKTElement("POLYGON((0 0,4 0,4 4,0 4,0 0))", srid=3857)
            )
        )

    session.commit()

    set_country_codes()

    assert session.query(tables.osm_polygon).get(1).country_code == 'ch'
