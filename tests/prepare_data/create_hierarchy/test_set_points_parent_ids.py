from geoalchemy2.elements import WKTElement
from osmnames.prepare_data.create_hierarchy import set_points_parent_ids, create_parent_polygons


def test_point_parent_id_get_set(session, tables):
    session.add(
            tables.osm_point(
                id=1,
                name="Some point with missing parent",
                type='town',
                place_rank=20,
                geometry=WKTElement("POINT(2 2)", srid=3857)
            )
        )

    session.add(
            tables.osm_polygon(
                id=2,
                name="Some Polygon covering the point",
                place_rank=16,
                type='state',
                geometry=WKTElement("POLYGON((0 0,4 0,4 4,0 4,0 0))", srid=3857)
            )
        )

    session.commit()

    create_parent_polygons()
    set_points_parent_ids()

    assert session.query(tables.osm_point).get(1).parent_id == 2


def test_point_parent_id_get_not_set_if_place_rank_lower(session, tables):
    session.add(
            tables.osm_point(
                id=1,
                name="Some point with missing parent",
                type='town',
                place_rank=2,
                geometry=WKTElement("POINT(2 2)", srid=3857)
            )
        )

    session.add(
            tables.osm_polygon(
                id=2,
                name="Some Polygon covering the point but higher place_rank",
                place_rank=20,
                type='state',
                geometry=WKTElement("POLYGON((0 0,4 0,4 4,0 4,0 0))", srid=3857)
            )
        )

    session.commit()

    create_parent_polygons()
    set_points_parent_ids()

    assert session.query(tables.osm_point).get(1).parent_id is None
