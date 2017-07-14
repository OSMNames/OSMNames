import pytest
import os

from geoalchemy2.elements import WKTElement
from osmnames.database.functions import exec_sql_from_file
from osmnames.import_osm.create_hierarchy import set_parent_id_for_linestrings_intersecting_multiple_polygons


@pytest.fixture(scope="function")
def schema(engine):
    current_directory = os.path.dirname(os.path.realpath(__file__))
    exec_sql_from_file('../fixtures/test_prepare_imported_data.sql.dump', cwd=current_directory)


# issue https://github.com/OSMNames/OSMNames/issues/79
def test_linestring_parent_id_get_set_with_most_overlapping_polygon(session, schema, tables):
    session.add(
            tables.osm_linestring(
                id=1,
                osm_id=25650226,
                name="Bietinger Weg (which crosses a border)",
                geometry=WKTElement("""LINESTRING(964325.504274035
                    6058403.91909057,964772.621700702 6058357.62003331)""", srid=3857)
            )
        )

    session.add(
            tables.osm_polygon(
                id=2,
                osm_id=-1683703,
                name="Schaffhausen",
                place_rank=22,
                parent_id=1,
                type='city',
                geometry=WKTElement("""POLYGON((950780.204111859 6063212.30455326,969117.169147176
                    6060704.86141201,964374.807650203 6054659.28237665,950780.204111859
                    6063212.30455326))""", srid=3857)
            )
        )

    session.add(
            tables.osm_polygon(
                id=3,
                osm_id=-2785126,
                name="Buesingen am Hochrhein",
                place_rank=22,
                parent_id=1,
                type='city',
                geometry=WKTElement("""POLYGON((963869.951901861 6055659.0183817,964544.74754235
                6059302.14781332,968620.916296797 6059604.16227536,970467.245624132
                6055551.35469413,963869.951901861 6055659.0183817))""", srid=3857)
            )
        )

    session.commit()

    set_parent_id_for_linestrings_intersecting_multiple_polygons()

    assert session.query(tables.osm_linestring).get(1).parent_id == 2
    assert session.query(tables.osm_linestring).get(1).intersecting_polygon_ids == [2, 3]
