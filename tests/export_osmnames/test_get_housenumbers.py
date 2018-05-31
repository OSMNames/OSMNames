def test_get_housenumbers_if_one_exists(session, tables):
    session.add(tables.osm_housenumber(street_id=1337, housenumber="12"))

    session.commit()

    assert get_housenumbers(session, 1337) == "12"


def test_get_housenumbers_if_multiple_exists(session, tables):
    session.add(tables.osm_housenumber(street_id=1337, housenumber="12"))
    session.add(tables.osm_housenumber(street_id=1337, housenumber="13"))

    session.commit()

    assert get_housenumbers(session, 1337) == "12, 13"


def test_get_housenumbers_if_others_exists(session, tables):
    session.add(tables.osm_housenumber(street_id=42, housenumber="12"))

    session.commit()

    assert get_housenumbers(session, 1337) is None


def test_get_housenumbers_if_no_exists(session, tables):
    assert get_housenumbers(session, 1337) is None


def get_housenumbers(session, osm_id):
    query = "SELECT get_housenumbers('{}')".format(osm_id)
    return session.execute(query).fetchone()[0]
