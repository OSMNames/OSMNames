from osmnames.prepare_data.create_hierarchy import create_parent_polygons


def test_parent_polygons_contains_correct_polygons(session, tables):
    session.add(
            tables.osm_polygon(
                id=1,
                name="should be included",
                type='town',
                place_rank=22,
            )
        )

    session.add(
            tables.osm_polygon(
                id=2,
                name="should be included (type = 'island' but admin_level != NULL)",
                type='island',
                place_rank=20,
                admin_level=8,
            )
        )

    session.add(
            tables.osm_polygon(
                id=3,
                name="should be excluded (place_rank > 22",
                type='town',
                place_rank=23,
            )
        )

    session.add(
            tables.osm_polygon(
                id=4,
                name="should be excluded (type = 'water')",
                type='water',
                place_rank=20,
            )
        )

    session.commit()

    create_parent_polygons()

    parent_polygons_ids = [polygon.id for polygon in session.query(tables.parent_polygons)]
    assert parent_polygons_ids == [1, 2]


def test_parent_polygons_orders_polygons_by_place_rank(session, tables):
    session.add(
            tables.osm_polygon(
                id=1,
                type='town',
                place_rank=18,
            )
        )

    session.add(
            tables.osm_polygon(
                id=2,
                type='town',
                place_rank=22,
            )
        )

    session.add(
            tables.osm_polygon(
                id=3,
                type='town',
                place_rank=17,
            )
        )

    session.commit()

    create_parent_polygons()

    parent_polygons_ids = [polygon.id for polygon in session.query(tables.parent_polygons)]
    assert parent_polygons_ids == [2, 1, 3]
