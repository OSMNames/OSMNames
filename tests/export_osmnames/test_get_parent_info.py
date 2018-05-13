def test_get_parent_info_1(session, tables):
    session.add(
            tables.osm_polygon(
                id=1,
                name="a small lake",
                type="water",
                place_rank=16,
                parent_id=2
            )
        )

    session.add(
            tables.osm_polygon(
                id=2,
                name="a village",
                type="administrative",
                place_rank=19,
                parent_id=3
            )
        )

    session.add(
            tables.osm_polygon(
                id=3,
                name="a town",
                type="administrative",
                place_rank=18,
                parent_id=4
            )
        )

    session.add(
        tables.osm_polygon(
            id=4,
            name="a city",
            type="administrative",
            place_rank=16,
            parent_id=5
        )
    )

    session.add(
        tables.osm_polygon(
            id=5,
            name="a county",
            type="administrative",
            place_rank=12,
            parent_id=6
        )
    )

    session.add(
        tables.osm_polygon(
            id=6,
            name="a state",
            type="administrative",
            place_rank=8,
            parent_id=7
        )
    )

    session.add(
        tables.osm_polygon(
            id=7,
            name="a country",
            type="administrative",
            country_code="ch",
            place_rank=4
        )
    )
    session.commit()

    parent_info = get_parent_info(session, 1, "")

    # state, county, city, country_code and display_name
    assert parent_info[0] == "ch"
    assert parent_info[1] == "a state"
    assert parent_info[2] == "a county"
    assert parent_info[3] == "a city"
    assert parent_info[4] == "a small lake, a village, a town, a city, a county, a state, a country"


def test_get_parent_info_2(session, tables):

    session.add(
            tables.osm_linestring(
                id=1,
                name="Halkova",
                place_rank=26,
                parent_id=2
            )
        )

    session.add(
            tables.osm_polygon(
                id=2,
                name="Rakovnik",
                type="administrative",
                place_rank=16,
                parent_id=3
            )
        )

    session.add(
            tables.osm_polygon(
                id=3,
                name="Okres Rakovnik",
                type="administrative",
                place_rank=14,
                parent_id=4
            )
        )

    session.add(
        tables.osm_polygon(
            id=4,
            name="Stredocesky kraj",
            type="administrative",
            place_rank=12,
            parent_id=5
        )
    )

    session.add(
        tables.osm_polygon(
            id=5,
            name="Czech Republic",
            type="administrative",
            country_code="cz",
            place_rank=4
        )
    )
    session.commit()

    parent_info = get_parent_info(session, 2, "Halkova")

    # state, county, city, country_code and display_name
    assert parent_info[0] == "cz"
    assert parent_info[1] == "Stredocesky kraj"
    assert parent_info[2] == "Okres Rakovnik"
    assert parent_info[3] == "Rakovnik"
    assert parent_info[4] == "Halkova, Rakovnik, Okres Rakovnik, Stredocesky kraj, Czech Republic"


def test_get_parent_info_3(session, tables):

    session.add(
            tables.osm_linestring(
                id=1,
                name="Oberseestrasse",
                place_rank=26,
                parent_id=2
            )
        )

    session.add(
            tables.osm_polygon(
                id=2,
                name="Rapperswil-Jona",
                type="administrative",
                place_rank=16,
                parent_id=3
            )
        )

    session.add(
            tables.osm_polygon(
                id=3,
                name="Wahlkreis See-Gaster",
                type="administrative",
                place_rank=12,
                parent_id=4
            )
        )

    session.add(
        tables.osm_polygon(
            id=4,
            name="Sankt Gallen",
            type="administrative",
            place_rank=8,
            parent_id=5
        )
    )

    session.add(
        tables.osm_polygon(
            id=5,
            name="Switzerland",
            type="administrative",
            country_code="ch",
            place_rank=4
        )
    )
    session.commit()

    parent_info = get_parent_info(session, 2, "Oberseestrasse")

    # state, county, city, country_code and display_name
    assert parent_info[0] == "ch"
    assert parent_info[1] == "Sankt Gallen"
    assert parent_info[2] == "Wahlkreis See-Gaster"
    assert parent_info[3] == "Rapperswil-Jona"
    assert parent_info[4] == "Oberseestrasse, Rapperswil-Jona, Wahlkreis See-Gaster, Sankt Gallen, Switzerland"


def test_city_name_gets_set(session, tables):

    session.add(
            tables.osm_polygon(
                id=1,
                name="Jona",
                type="administrative",
                place_rank=16
            )
        )
    session.commit()

    parent_info = get_parent_info(session, 1, "")
    assert parent_info[3] == "Jona"


def get_parent_info(session, id, name):
    query = "SELECT get_parent_info({},'{}')".format(id, name)
    parent_info = session.execute(query).fetchone()[0].strip('(').strip(')').split(',')
    parent_info = [x.strip('"') for x in parent_info]
    parent_info[4] = ",".join(parent_info[4:])
    return parent_info
