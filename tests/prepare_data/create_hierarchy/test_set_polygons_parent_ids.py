from geoalchemy2.elements import WKTElement
from osmnames.prepare_data.create_hierarchy import set_polygons_parent_ids, create_parent_polygons


def test_polygon_parent_id_get_set_based_on_geometry(session, tables):
    session.add(
            tables.osm_polygon(
                id=1,
                name="Some polygon with missing parent",
                type='town',
                geometry=WKTElement("POLYGON((2 2,4 0,4 4,0 4,2 2))", srid=3857)
            )
        )

    session.add(
            tables.osm_polygon(
                id=2,
                name="Some Polygon covering the polygon",
                place_rank=20,
                type='state',
                geometry=WKTElement("POLYGON((0 0,4 0,4 4,0 4,0 0))", srid=3857)
            )
        )

    session.commit()

    create_parent_polygons()
    set_polygons_parent_ids()

    assert session.query(tables.osm_polygon).get(1).parent_id == 2


def test_polygon_parent_id_NOT_set_if_polygon_not_fully_covered(session, tables):
    session.add(
            tables.osm_polygon(
                id=1,
                name="Some polygon with missing parent",
                type='town',
                geometry=WKTElement("POLYGON((2 0,6 0,4 4,0 4,2 0))", srid=3857)
            )
        )

    session.add(
            tables.osm_polygon(
                id=2,
                name="Some Polygon covering the polygon",
                place_rank=20,
                type='state',
                geometry=WKTElement("POLYGON((0 0,4 0,4 4,0 4,0 0))", srid=3857)
            )
        )

    session.commit()

    create_parent_polygons()
    set_polygons_parent_ids()

    assert session.query(tables.osm_polygon).get(1).parent_id is None


def test_osm_polygon_parent_id_get_set_with_nearest_rank(session, tables):
    session.add(
            tables.osm_polygon(
                id=1,
                name="Some Polygon with missing parent",
                place_rank=20,
                type='city',
                geometry=WKTElement("POINT(2 2)", srid=3857)
            )
        )

    session.add(
            tables.osm_polygon(
                id=2,
                name="Some Polygon with higher rank, covering the other polygon",
                place_rank=8,
                type='continent',
                geometry=WKTElement("POLYGON((0 0,4 0,4 4,0 4,0 0))", srid=3857)
            )
        )

    session.add(
            tables.osm_polygon(
                id=3,
                name="Some Polygon with same rank, covering the other polygon",
                place_rank=16,
                type='country',
                geometry=WKTElement("POLYGON((0 0,4 0,4 4,0 4,0 0))", srid=3857)
            )
        )

    session.commit()

    create_parent_polygons()
    set_polygons_parent_ids()

    assert session.query(tables.osm_polygon).get(1).parent_id == 3


def test_osm_polygon_parent_id_get_NOT_set_if_place_rank_is_lower(session, tables):
    session.add(
            tables.osm_polygon(
                id=1,
                name="Some Polygon with missing parent",
                place_rank=12,
                type='city',
                geometry=WKTElement("POINT(2 2)", srid=3857)
            )
        )

    session.add(
            tables.osm_polygon(
                id=2,
                name="Some Polygon covering the other polygon",
                place_rank=20,
                type='country',
                geometry=WKTElement("POLYGON((0 0,4 0,4 4,0 4,0 0))", srid=3857)
            )
        )

    session.commit()

    create_parent_polygons()
    set_polygons_parent_ids()

    assert session.query(tables.osm_polygon).get(1).parent_id is None


def test_osm_polygon_parent_id_get_set_if_place_rank_not_provided(session, tables):
    session.add(
            tables.osm_polygon(
                id=1,
                name="Some Polygon with missing parent and place_rank",
                type='city',
                geometry=WKTElement("POINT(2 2)", srid=3857)
            )
        )

    session.add(
            tables.osm_polygon(
                id=2,
                name="Some Polygon covering the other polygon",
                place_rank=20,
                type='country',
                geometry=WKTElement("POLYGON((0 0,4 0,4 4,0 4,0 0))", srid=3857)
            )
        )

    session.commit()

    create_parent_polygons()
    set_polygons_parent_ids()

    assert session.query(tables.osm_polygon).get(1).parent_id == 2
