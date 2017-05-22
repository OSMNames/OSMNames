import pytest
import os

from osmnames.database.functions import exec_sql_from_file
from osmnames.export_osmnames.export_osmnames import create_functions


@pytest.fixture(scope="function")
def schema(engine):
    current_directory = os.path.dirname(os.path.realpath(__file__))
    exec_sql_from_file('fixtures/test_export_osmnames.sql.dump', cwd=current_directory)
    create_functions()


def test_returns_importance_via_wikipedia_column_if_exists(session, schema, tables):
    session.add(tables.wikipedia_article(language="de", title="Hombrechtikon", importance=10))
    session.commit()

    importance = get_importance(session, 12, "de:Hombrechtikon", "ch")

    assert importance == 10


def test_priority_1_is_language_from_given_wikipedia_string(session, schema, tables):
    session.add(tables.wikipedia_article(language="es", title="Hombrechtikon", importance=10))
    session.add(tables.wikipedia_article(language="en", title="Hombrechtikon", importance=8))
    session.add(tables.wikipedia_article(language="de", title="Hombrechtikon", importance=6))
    session.commit()

    importance = get_importance(session, 12, "de:Hombrechtikon", "ch")

    assert importance == 6


def test_priority_2_is_english_wikipedia_article(session, schema, tables):
    session.add(tables.wikipedia_article(language="es", title="Hombrechtikon", importance=10))
    session.add(tables.wikipedia_article(language="en", title="Hombrechtikon", importance=6))
    session.commit()

    importance = get_importance(session, 12, "de:Hombrechtikon", "ch")

    assert importance == 6


def test_priority_3_is_default_countries_language(session, schema, tables):
    session.add(tables.country_name(country_code="us", country_default_language_code='en'))
    session.add(tables.wikipedia_article(language="es", title="NewYork", importance=12))
    session.add(tables.wikipedia_article(language="en", title="NewYork", importance=11))
    session.commit()

    importance = get_importance(session, 12, "de:NewYork", "us")

    assert importance == 11


def test_priority_4_other_languages(session, schema, tables):
    session.add(tables.wikipedia_article(language="es", title="Hombrechtikon", importance=12))
    session.add(tables.wikipedia_article(language="zh", title="Hombrechtikon", importance=13))
    session.commit()

    importance = get_importance(session, 12, "en:Hombrechtikon", "ch")

    assert importance == 13


def test_calculates_importance_if_no_wikipedia_article_exists(session, schema, tables):
    importance = get_importance(session, 12, "de:Hombrechtikon", "ch")

    assert importance == 0.45


def test_calculates_importance_if_no_wikipedia_article_defined(session, schema, tables):
    importance = get_importance(session, 12, "", "ch")

    assert importance == 0.45


def get_importance(session, place_rank, wikipedia, country_code):
    query = "SELECT get_importance({},'{}','{}')".format(place_rank, wikipedia, country_code)
    return session.execute(query).fetchone()[0]
