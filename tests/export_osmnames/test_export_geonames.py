import os

from osmnames.export_osmnames.export_osmnames import export_geonames, create_export_dir, create_views


def test_tsv_get_created(session, tables):
    session.add(
            tables.osm_polygon(
                id=1,
                name="Just a city",
            )
        )
    create_export_dir()
    create_views()

    export_geonames()

    assert os.path.exists('/tmp/osmnames/export/test_geonames.tsv')
