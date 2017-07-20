import pytest
import os

from osmnames.database.functions import exec_sql_from_file
from osmnames.import_osm.set_names import set_linestring_names_from_relations


@pytest.fixture(scope="module")
def schema():
    current_directory = os.path.dirname(os.path.realpath(__file__))
    exec_sql_from_file('../fixtures/test_prepare_imported_data.sql.dump', cwd=current_directory)


def test_name_is_set_if_linestring_is_relation_member_with_role_street(session, schema, tables):
    session.add(tables.osm_linestring(id=1111, name=""))
    session.add(tables.osm_relation(osm_id=-9999, name="Oberfeldring"))
    session.add(tables.osm_relation_member(osm_id=-9999, member_id=1111, role="street"))

    session.commit()

    set_linestring_names_from_relations()
