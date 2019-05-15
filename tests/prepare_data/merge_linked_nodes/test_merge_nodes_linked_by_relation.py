from osmnames.prepare_data.merge_linked_nodes import merge_nodes_linked_by_relation


def test_attributes_from_admin_center_nodes_are_added_to_polygon_with_same_name(session, tables):
    session.add(tables.osm_polygon(id=1, osm_id=1337, name="Zuerich", all_tags={"name:en": "Zurich"}))
    session.add(tables.osm_polygon(id=2, osm_id=42, name="Kanton Zuerich", all_tags={"name:en": "Canton Zurich"}))
    session.add(tables.osm_point(osm_id=43, name="Zuerich", all_tags={"name:ch": "Züri"}, wikipedia="de:Zürich", wikidata="Q47"))
    session.add(tables.osm_relation_member(member_id=43, member_type=0, role="admin_center", osm_id=1337))
    session.add(tables.osm_relation_member(member_id=43, member_type=0, role="admin_center", osm_id=42))
    session.commit()

    merge_nodes_linked_by_relation()

    # attributes are added to the polygon with osm_id 1337 because admin_center has the same name
    assert session.query(tables.osm_polygon).get(1).all_tags == {"name:en": "Zurich", "name:ch": "Züri"}
    assert session.query(tables.osm_polygon).get(1).wikipedia == "de:Zürich"
    assert session.query(tables.osm_polygon).get(1).wikidata == "Q47"
    assert session.query(tables.osm_polygon).get(1).merged_osm_id == 43

    # attributes are NOT added to the polygon with osm_id 42 because admin_center has a different name
    assert session.query(tables.osm_polygon).get(2).all_tags == {"name:en": "Canton Zurich"}


def test_attributes_from_admin_center_nodes_are_added_to_polygon_with_same_wikipedia(session, tables):
    session.add(tables.osm_polygon(id=1, osm_id=1337, name="Züri", wikipedia="de:Zürich", all_tags={"name:en": "Zurich"}))
    session.add(tables.osm_point(osm_id=43, name="Zuerich", all_tags={"name:ch": "Züri"}, wikipedia="de:Zürich"))
    session.add(tables.osm_relation_member(member_id=43, member_type=0, role="admin_center", osm_id=1337))
    session.commit()

    merge_nodes_linked_by_relation()

    # attributes are added to the polygon with osm_id 1337 because admin_center has the same name
    assert session.query(tables.osm_polygon).get(1).all_tags == {"name:en": "Zurich", "name:ch": "Züri"}
    assert session.query(tables.osm_polygon).get(1).wikipedia == "de:Zürich"
    assert session.query(tables.osm_polygon).get(1).merged_osm_id == 43


def test_merged_admin_centers_nodes_are_deleted(session, tables):
    session.add(tables.osm_polygon(id=1, osm_id=1337, name="Züri", wikidata="Q42", all_tags={"name:en": "Zurich"}))
    session.add(tables.osm_point(id=1, osm_id=43, name="Zuerich", all_tags={"name:ch": "Züri"}, wikidata="Q42"))
    session.add(tables.osm_relation_member(member_id=43, member_type=0, role="admin_center", osm_id=1337))
    session.commit()

    merge_nodes_linked_by_relation()

    assert session.query(tables.osm_point).get(1) is None


def test_attributes_from_label_nodes_are_added_to_polygon(session, tables):
    session.add(tables.osm_polygon(id=1, osm_id=1337, all_tags={"name:en": "Zurich"}, wikidata='', wikipedia=''))
    session.add(tables.osm_relation_member(member_id=43, member_type=0, role="label", osm_id=1337))
    session.add(tables.osm_point(osm_id=43, all_tags={"name:ch": "Züri"}, wikipedia="de:Zürich", wikidata="Q47"))
    session.commit()

    merge_nodes_linked_by_relation()

    assert session.query(tables.osm_polygon).get(1).all_tags == {"name:en": "Zurich", "name:ch": "Züri"}
    assert session.query(tables.osm_polygon).get(1).wikipedia == "de:Zürich"
    assert session.query(tables.osm_polygon).get(1).wikidata == "Q47"
    assert session.query(tables.osm_polygon).get(1).merged_osm_id == 43


def test_merged_label_nodes_are_deleted(session, tables):
    session.add(tables.osm_polygon(id=1, osm_id=1337, all_tags={"name:en": "Zurich"}))
    session.add(tables.osm_relation_member(member_id=43, member_type=0, role="label", osm_id=1337))
    session.add(tables.osm_point(id=1, osm_id=43, all_tags={"name:ch": "Züri"}, wikipedia="de:Zürich", wikidata="Q47"))
    session.commit()

    merge_nodes_linked_by_relation()

    assert session.query(tables.osm_point).get(1) is None


def test_attributes_from_political_nodes_are_added_to_polygon(session, tables):
    session.add(tables.osm_polygon(id=1, osm_id=-5396194, all_tags={"name:en": "Washington D.C."}))
    session.add(tables.osm_relation_member(member_id=158368533, member_type=0, role="Political", osm_id=-5396194))
    session.add(tables.osm_point(osm_id=158368533, all_tags={"name:de": "Washington"}, wikipedia="en:Washington"))
    session.commit()

    merge_nodes_linked_by_relation()

    assert session.query(tables.osm_polygon).get(1).all_tags == {"name:en": "Washington D.C.", "name:de": "Washington"}
    assert session.query(tables.osm_polygon).get(1).wikipedia == "en:Washington"
    assert session.query(tables.osm_polygon).get(1).merged_osm_id == 158368533
