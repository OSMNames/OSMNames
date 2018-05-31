import os

from osmnames.export_osmnames.export_osmnames import export_housenumbers, create_views


def test_tsv_get_created(session, tables):
    session.add(
            tables.osm_housenumber(
                osm_id=1,
            )
        )
    create_views()

    export_housenumbers()

    assert os.path.exists('/tmp/osmnames/export/switzerland_housenumbers.tsv')
