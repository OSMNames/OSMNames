from geoalchemy2.elements import WKTElement
from osmnames.prepare_data.create_hierarchy import set_housenumbers_parent_ids, create_parent_polygons


def test_housenumber_parent_id_get_set_based_on_geometry_center(session, tables):
    session.add(
            tables.osm_housenumber(
                id=1,
                name="Some housenumber with missing parent",
                geometry_center=WKTElement("POINT(2 2)", srid=3857)
            )
        )

    session.add(
            tables.osm_polygon(
                id=2,
                name="Some Polygon covering the housenumber",
                place_rank=20,
                type='city',
                geometry=WKTElement("POLYGON((0 0,4 0,4 4,0 4,0 0))", srid=3857)
            )
        )

    session.commit()

    create_parent_polygons()
    set_housenumbers_parent_ids()

    assert session.query(tables.osm_housenumber).get(1).parent_id == 2
