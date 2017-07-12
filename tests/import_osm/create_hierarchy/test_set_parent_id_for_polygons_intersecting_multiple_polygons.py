import pytest
import os

from geoalchemy2.elements import WKTElement
from osmnames.database.functions import exec_sql_from_file
from osmnames.import_osm.create_hierarchy import set_parent_id_for_polygons_intersecting_multiple_polygons


@pytest.fixture(scope="function")
def schema(engine):
    current_directory = os.path.dirname(os.path.realpath(__file__))
    exec_sql_from_file('../fixtures/test_prepare_imported_data.sql.dump', cwd=current_directory)


def test_most_overlapping_polygon_ignored_if_admin_level_lower(session, schema, tables):
    session.add(
            tables.osm_polygon(
                id=1,
                name="Polygon with low admin_level",
                place_rank=10,
                geometry=WKTElement("""POLYGON((950780.204111859 6063212.30455326,969117.169147176
                    6060704.86141201,964374.807650203 6054659.28237665,950780.204111859
                    6063212.30455326))""", srid=3857)
            )
        )

    session.add(
            tables.osm_polygon(
                id=2,
                name="Overlapping Polygon with high admin_level",
                place_rank=22,
                geometry=WKTElement("""POLYGON((950780.204111859 6063212.30455326,969117.169147176
                    6060704.86141201,964374.807650203 6054659.28237665,950780.204111859
                    6063212.30455326))""", srid=3857)
            )
        )

    session.commit()

    set_parent_id_for_polygons_intersecting_multiple_polygons()

    assert session.query(tables.osm_polygon).get(1).parent_id is None
