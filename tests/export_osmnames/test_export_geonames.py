import pytest
import os

from osmnames.database.functions import exec_sql_from_file
from osmnames.export_osmnames.export_osmnames import export_geonames, create_functions, create_views


@pytest.fixture(scope="function")
def schema(engine):
    current_directory = os.path.dirname(os.path.realpath(__file__))
    exec_sql_from_file('fixtures/test_export_osmnames.sql.dump', cwd=current_directory)
    create_functions()

    if not os.path.exists('/tmp/osmnames/export/'):
        os.makedirs('/tmp/osmnames/export/')


def test_tsv_get_created(session, schema, tables):
    session.add(
            tables.osm_polygon(
                id=1,
                name="Just a city",
            )
        )
    create_views()

    export_geonames()

    assert os.path.exists('/tmp/osmnames/export/switzerland_geonames.tsv')
