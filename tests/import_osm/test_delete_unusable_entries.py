import pytest
import os

from osmnames.helpers.database import exec_sql_from_file
from osmnames.import_osm import import_osm
from helpers.database import table_class_for


@pytest.fixture(scope="module")
def schema():
    current_directory = os.path.dirname(os.path.realpath(__file__))
    exec_sql_from_file('fixtures/test_delete_unusable_entries_schema.sql.dump', cwd=current_directory)


def test_osm_polygon_tmp_with_blank_names_get_deleted(engine, session, schema):
    osm_polygon_tmp = table_class_for("osm_polygon_tmp", engine)

    session.add(osm_polygon_tmp(name="gugus"))
    session.add(osm_polygon_tmp(name_en=""))
    session.commit()

    import_osm.delete_unusable_entries()

    assert session.query(osm_polygon_tmp).count(), 1


def test_osm_point_tmp_with_blank_names_get_deleted(engine, session, schema):
    osm_point_tmp = table_class_for("osm_point_tmp", engine)

    session.add(osm_point_tmp(name_de="gugus"))
    session.add(osm_point_tmp(name_en=""))
    session.commit()

    import_osm.delete_unusable_entries()

    assert session.query(osm_point_tmp).count(), 1


def test_osm_linestring_tmp_with_blank_names_get_deleted(engine, session, schema):
    osm_linestring_tmp = table_class_for("osm_linestring_tmp", engine)

    session.add(osm_linestring_tmp(name_zh="gugus"))
    session.add(osm_linestring_tmp(name_en=""))
    session.commit()

    import_osm.delete_unusable_entries()

    assert session.query(osm_linestring_tmp).count(), 1
