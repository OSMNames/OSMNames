import pytest
import os

from geoalchemy2.elements import WKTElement
from osmnames.helpers.database import exec_sql_from_file
from osmnames.import_osm.import_osm import prepare_housenumbers
from helpers.database import table_class_for


@pytest.fixture(scope="function")
def schema(engine):
    current_directory = os.path.dirname(os.path.realpath(__file__))
    exec_sql_from_file('fixtures/test_prepare_housenumbers.sql.dump', cwd=current_directory)


def test_street_get_completed_if_associatedStreet_relation_exists(engine, session, schema):
    osm_housenumber_tmp = table_class_for("osm_housenumber_tmp", engine)
    osm_relation = table_class_for("osm_relation", engine)
    osm_relation_member = table_class_for("osm_relation_member", engine)

    session.add(
            osm_housenumber_tmp(
                id=1,
                osm_id=466015291,
                geometry=WKTElement("POINT(937751.833613385 5993981.31662329)", srid=3857)
                )
            )

    session.add(osm_relation(osm_id=-196529, type="associatedStreet", name="Oberfeldring"))
    session.add(osm_relation_member(osm_id=-196529, member_id=466015291))

    session.commit()

    prepare_housenumbers()

    assert str(session.query(osm_housenumber_tmp).get(1).name) == "Oberfeldring"
