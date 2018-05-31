from geoalchemy2.elements import WKTElement
from osmnames.prepare_data.prepare_data import delete_unusable_entries

POLYGON_GEOMETRY = WKTElement('POLYGON((1 2, 3 4, 5 6, 1 2))', srid=3857)


def test_osm_polygon_with_blank_names_get_deleted(session, tables):
    session.add(tables.osm_polygon(name="gugus"))
    session.add(tables.osm_polygon(name=""))
    session.commit()

    delete_unusable_entries()

    assert session.query(tables.osm_polygon).count() == 1


def test_osm_polygon_with_null_names_get_deleted(session, tables):
    session.add(tables.osm_polygon(name="gugus"))
    session.add(tables.osm_polygon())
    session.commit()

    delete_unusable_entries()

    assert session.query(tables.osm_polygon).count() == 1


def test_osm_point_with_blank_names_get_deleted(session, tables):
    session.add(tables.osm_point(name="gugus"))
    session.add(tables.osm_point(name=""))
    session.commit()

    delete_unusable_entries()

    assert session.query(tables.osm_point).count() == 1


def test_osm_linestring_with_blank_names_get_deleted(session, tables):
    session.add(tables.osm_linestring(name="gugus"))
    session.add(tables.osm_linestring(name=""))
    session.commit()

    delete_unusable_entries()

    assert session.query(tables.osm_linestring).count() == 1


def test_osm_polygon_with_empty_geometries_get_deleted(session, tables):
    session.add(tables.osm_polygon(name="some polygon", geometry=POLYGON_GEOMETRY))
    session.add(tables.osm_polygon(name="an empty polygon", geometry=WKTElement('POLYGON EMPTY', srid=3857)))
    session.commit()

    delete_unusable_entries()

    assert session.query(tables.osm_polygon).count() == 1


def test_osm_linestring_get_deleted_if_polygon_with_same_osm_id_exists(session, tables):
    session.add(tables.osm_linestring(name="some linestring", osm_id=1337))
    session.add(tables.osm_polygon(name="some polygon", osm_id=1337, geometry=POLYGON_GEOMETRY))
    session.commit()

    delete_unusable_entries()

    assert session.query(tables.osm_linestring).count() == 0
    assert session.query(tables.osm_polygon).count() == 1
