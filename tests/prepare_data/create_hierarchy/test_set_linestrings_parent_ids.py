from geoalchemy2.elements import WKTElement
from osmnames.prepare_data.create_hierarchy import set_linestrings_parent_ids, create_parent_polygons


def test_linestring_parent_id_get_set_based_on_geometry_center(session, tables):
    session.add(
            tables.osm_linestring(
                id=1,
                name="Some linestring with missing parent",
                type='street',
                geometry_center=WKTElement("POINT(2 2)", srid=3857)
            )
        )

    session.add(
            tables.osm_polygon(
                id=2,
                name="Some Polygon covering the linestring",
                place_rank=20,
                type='city',
                geometry=WKTElement("POLYGON((0 0,4 0,4 4,0 4,0 0))", srid=3857)
            )
        )

    session.commit()

    create_parent_polygons()
    set_linestrings_parent_ids()

    assert session.query(tables.osm_linestring).get(1).parent_id == 2
