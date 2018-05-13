def test_returns_importance_via_wikipedia_column_if_exists(session, tables):
    session.add(tables.wikipedia_article(language="de", title="Hombrechtikon", importance=10))
    session.commit()

    importance = get_importance(session, 12, "de:Hombrechtikon", "ch")

    assert importance == 10


def test_priority_1_is_language_from_given_wikipedia_string(session, tables):
    session.add(tables.wikipedia_article(language="es", title="Hombrechtikon", importance=10))
    session.add(tables.wikipedia_article(language="en", title="Hombrechtikon", importance=8))
    session.add(tables.wikipedia_article(language="de", title="Hombrechtikon", importance=6))
    session.commit()

    importance = get_importance(session, 12, "de:Hombrechtikon", "ch")

    assert importance == 6


def test_priority_2_is_english_wikipedia_article(session, tables):
    session.add(tables.wikipedia_article(language="es", title="Hombrechtikon", importance=10))
    session.add(tables.wikipedia_article(language="en", title="Hombrechtikon", importance=6))
    session.commit()

    importance = get_importance(session, 12, "de:Hombrechtikon", "ch")

    assert importance == 6


def test_priority_3_is_default_countries_language(session, tables):
    session.add(tables.country_name(country_code="us", country_default_language_code='en'))
    session.add(tables.wikipedia_article(language="es", title="NewYork", importance=12))
    session.add(tables.wikipedia_article(language="en", title="NewYork", importance=11))
    session.commit()

    importance = get_importance(session, 12, "de:NewYork", "us")

    assert importance == 11


def test_priority_4_other_languages(session, tables):
    session.add(tables.wikipedia_article(language="es", title="Hombrechtikon", importance=12))
    session.add(tables.wikipedia_article(language="zh", title="Hombrechtikon", importance=13))
    session.commit()

    importance = get_importance(session, 12, "en:Hombrechtikon", "ch")

    assert importance == 13


def test_calculates_importance_if_no_wikipedia_article_exists(session, tables):
    importance = get_importance(session, 12, "de:Hombrechtikon", "ch")

    assert importance == 0.45


def test_calculates_importance_if_no_wikipedia_article_defined(session, tables):
    importance = get_importance(session, 12, "", "ch")

    assert importance == 0.45


def get_importance(session, place_rank, wikipedia, country_code):
    query = "SELECT get_importance({},'{}','{}')".format(place_rank, wikipedia, country_code)
    return session.execute(query).fetchone()[0]
