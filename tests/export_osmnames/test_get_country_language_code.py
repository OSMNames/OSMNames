def test_if_default_language_present(session, tables):
    session.add(tables.country_name(country_code="ch", country_default_language_code="DE"))

    session.commit()

    assert get_country_language_code(session, "ch") == "de"


def test_if_default_language_not_present(session, tables):
    session.add(tables.country_name(country_code="ch", country_default_language_code="DE"))

    session.commit()

    assert get_country_language_code(session, "en") is None


def get_country_language_code(session, country_code):
    query = "SELECT get_country_language_code('{}')".format(country_code)
    return session.execute(query).fetchone()[0]
