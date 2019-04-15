from osmnames.prepare_data.prepare_data import follow_wikipedia_redirects


def test_updates_with_redirects(session, tables):
    session.add(
            tables.osm_linestring(
                id=1,
                wikipedia="en:should_be_redirected"
            )
        )
    session.add(
            tables.osm_linestring(
                id=2,
                wikipedia="en:should_not_be_redirected"
            )
        )
    session.add(
            tables.wikipedia_redirect(
                from_title="en:should_be_redirected",
                to_title="en:redirection_destination",
            )
        )

    session.commit()

    follow_wikipedia_redirects()

    assert session.query(tables.osm_linestring).get(1).wikipedia == "en:redirection_destination"
    assert session.query(tables.osm_linestring).get(2).wikipedia == "en:should_not_be_redirected"


def test_follows_english_redirects_as_fallback(session, tables):
    session.add(
            tables.osm_polygon(
                id=1,
                wikipedia="el:Ελλάδα"
            )
        )

    session.add(
            tables.wikipedia_redirect(
                from_title="en:Ελλάδα",
                to_title="en:Greece",
            )
        )

    session.commit()

    follow_wikipedia_redirects()

    assert session.query(tables.osm_polygon).get(1).wikipedia == "en:Greece"
