import pytest
import os

from osmnames.helpers.database import exec_sql_from_file
from osmnames.import_osm.import_osm import set_place_ranks


@pytest.fixture(scope="function")
def schema(engine):
    current_directory = os.path.dirname(os.path.realpath(__file__))
    exec_sql_from_file('fixtures/test_prepare_imported_data.sql.dump', cwd=current_directory)


def test_osm_polygon_place_rank_get_set(session, schema, tables):
    session.add(
            tables.osm_polygon(
                id=1,
                name="Country polygon with missing place rank",
                type="country"
            )
        )

    session.commit()

    set_place_ranks()

    assert session.query(tables.osm_polygon).get(1).place_rank == 4


def test_osm_linestring_place_rank_get_set(session, schema, tables):
    session.add(
            tables.osm_linestring(
                id=1,
                name="Street linestring with missing place_rank",
                type="road"
            )
        )

    session.commit()

    set_place_ranks()

    assert session.query(tables.osm_linestring).get(1).place_rank == 26


def test_administrative_place_rank_gets_calculated_from_admin_level(session, schema, tables):
    session.add(
            tables.osm_polygon(
                id=1,
                admin_level="8",
                type="administrative"
            )
        )

    session.commit()

    set_place_ranks()

    assert session.query(tables.osm_polygon).get(1).place_rank == 16
