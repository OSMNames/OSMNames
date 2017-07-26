import pytest
import os

from osmnames.database.functions import exec_sql_from_file
from osmnames.export_osmnames.export_osmnames import create_functions


@pytest.fixture(scope="function")
def schema(engine):
    current_directory = os.path.dirname(os.path.realpath(__file__))
    exec_sql_from_file('fixtures/test_export_osmnames.sql.dump', cwd=current_directory)
    create_functions()


def test_if_default_language_present(session, schema, tables):
    session.add(tables.country_name(country_code="ch", country_default_language_code="DE"))

    session.commit()

    assert get_country_language_code(session, "ch") == "de"


def test_if_default_language_not_present(session, schema, tables):
    session.add(tables.country_name(country_code="ch", country_default_language_code="DE"))

    session.commit()

    assert get_country_language_code(session, "en") is None


def get_country_language_code(session, country_code):
    query = "SELECT get_country_language_code('{}')".format(country_code)
    return session.execute(query).fetchone()[0]
