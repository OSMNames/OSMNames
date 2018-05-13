from osmnames.prepare_data.prepare_data import determine_linked_places


def test_osm_polygon_label_get_linked(session, tables):
    session.add(tables.osm_polygon(osm_id=1337))
    session.add(tables.osm_relation_member(member_id=43, member_type=0, role="label", osm_id=1337))
    session.commit()

    determine_linked_places()

    assert session.query(tables.osm_polygon).get(1).linked_osm_ids == [43]


def test_osm_polygon_admin_center_get_linked(session, tables):
    session.add(tables.osm_polygon(osm_id=1337))
    session.add(tables.osm_relation_member(member_id=43, member_type=0, role="admin_center", osm_id=1337))
    session.commit()

    determine_linked_places()

    assert session.query(tables.osm_polygon).get(1).linked_osm_ids == [43]


def test_osm_point_is_set_to_linked(session, tables):
    session.add(tables.osm_polygon(linked_osm_ids=[1337]))
    session.add(tables.osm_point(id=1, osm_id=1337))
    session.commit()

    determine_linked_places()

    assert session.query(tables.osm_point).get(1).linked is True
