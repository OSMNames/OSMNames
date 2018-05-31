from osmnames.prepare_data.prepare_housenumbers import sanitize_housenumbers


def test_tabs_get_deleted_from_housenumber(session, tables):
    session.add(
        tables.osm_housenumber(
            id=1,
            housenumber="Some\t\tHousenumber"
            )
        )
    session.commit()
    sanitize_housenumbers()

    assert session.query(tables.osm_housenumber).get(1).housenumber == "Some Housenumber"


def test_newlines_get_replaced_from_housenumber(session, tables):
    session.add(
        tables.osm_housenumber(
            id=1,
            housenumber="#1\n#2"
            )
        )
    session.commit()
    sanitize_housenumbers()

    assert session.query(tables.osm_housenumber).get(1).housenumber == "#1, #2"
