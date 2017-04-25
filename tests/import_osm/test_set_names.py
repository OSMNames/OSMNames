import pytest
import os

from geoalchemy2.elements import WKTElement
from osmnames.database.functions import exec_sql_from_file
from osmnames.import_osm import import_osm


@pytest.fixture(scope="module")
def schema():
    current_directory = os.path.dirname(os.path.realpath(__file__))
    exec_sql_from_file('fixtures/test_prepare_imported_data.sql.dump', cwd=current_directory)


def test_name_get_set_from_all_tags(session, schema, tables):
    session.add(tables.osm_polygon(id=1, name="", all_tags={"name:en":"Zurich"}))
    session.add(tables.osm_linestring(id=1, name="", all_tags={"name:de":"Rhein"}))
    session.commit()

    import_osm.set_names()

    assert session.query(tables.osm_polygon).get(1).name == "Zurich"
    assert session.query(tables.osm_linestring).get(1).name == "Rhein"


def test_name_get_set_according_to_priority(session, schema, tables):
    session.add(
    	tables.osm_polygon(
			id=2,
			name="",
			all_tags={"name:fr":"Lac Leman","name:de":"Genfersee","name:en":"Lake Geneva"}
		)
    )

    session.add(
    	tables.osm_linestring(
			id=2,
			name="",
			all_tags={"name:es":"Rin","name:it":"Reno","name:de":"Rhein"}
		)
    )

    session.commit()

    import_osm.set_names()

    assert session.query(tables.osm_polygon).get(2).name == "Lake Geneva"
    assert session.query(tables.osm_linestring).get(2).name == "Rhein"
    