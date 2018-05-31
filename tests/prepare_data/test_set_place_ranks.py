from osmnames.prepare_data.prepare_data import set_place_ranks


def test_osm_polygon_place_rank_get_set(session, tables):
    session.add(
            tables.osm_polygon(
                id=1,
                name="Country polygon with missing place rank",
                type="country"
            )
        )

    session.commit()

    set_place_ranks()

    assert session.query(tables.osm_polygon).get(1).place_rank == 4


def test_osm_linestring_place_rank_get_set(session, tables):
    session.add(
            tables.osm_linestring(
                id=1,
                name="Street linestring with missing place_rank",
                type="road"
            )
        )

    session.commit()

    set_place_ranks()

    assert session.query(tables.osm_linestring).get(1).place_rank == 26


def test_administrative_place_rank_gets_calculated_from_admin_level(session, tables):
    session.add(
            tables.osm_polygon(
                id=1,
                admin_level="8",
                type="administrative"
            )
        )

    session.commit()

    set_place_ranks()

    assert session.query(tables.osm_polygon).get(1).place_rank == 16
