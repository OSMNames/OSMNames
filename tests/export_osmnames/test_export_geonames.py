import os

from osmnames.export_osmnames.export_osmnames import export_geonames, create_views


def test_tsv_get_created(session, tables):
    session.add(
            tables.osm_polygon(
                id=1,
                name="Just a city",
            )
        )
    create_views()

    export_geonames()

    assert os.path.exists('/tmp/osmnames/export/switzerland_geonames.tsv')
