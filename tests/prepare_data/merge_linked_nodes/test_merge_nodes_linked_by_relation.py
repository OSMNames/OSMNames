from osmnames.prepare_data.merge_linked_nodes import merge_nodes_linked_by_relation


def test_attributes_from_admin_center_nodes_are_added_to_polygon_with_same_name(session, tables):
    session.add(tables.osm_polygon(id=1, osm_id=1337, all_tags={"name:en": "Zurich"}))
    session.add(tables.osm_polygon(id=2, osm_id=42, all_tags={"name:en": "Canton Zurich"}))
    session.add(tables.osm_point(osm_id=43, all_tags={"name:en": "Zurich", "name:ch": "Züri"}, wikipedia="de:Zürich", wikidata="Q47"))
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
    session.add(tables.osm_polygon(id=1, osm_id=1337, wikipedia="de:Zürich", all_tags={"name:en": "Zurich"}))
    session.add(tables.osm_point(osm_id=43, all_tags={"name:ch": "Züri"}, wikipedia="de:Zürich"))
    session.add(tables.osm_relation_member(member_id=43, member_type=0, role="admin_center", osm_id=1337))
    session.commit()

    merge_nodes_linked_by_relation()

    assert session.query(tables.osm_polygon).get(1).all_tags == {"name:en": "Zurich", "name:ch": "Züri"}
    assert session.query(tables.osm_polygon).get(1).wikipedia == "de:Zürich"
    assert session.query(tables.osm_polygon).get(1).merged_osm_id == 43


def test_attributes_are_not_merged_if_wikipedia_ref_is_empty_and_no_name_overlaps(session, tables):
    session.add(tables.osm_polygon(id=1, osm_id=1337, wikipedia=""))
    session.add(tables.osm_point(osm_id=43, wikipedia=""))
    session.add(tables.osm_relation_member(member_id=43, member_type=0, role="admin_center", osm_id=1337))
    session.commit()

    merge_nodes_linked_by_relation()

    assert session.query(tables.osm_polygon).get(1).merged_osm_id is None
    assert not session.query(tables.osm_point).get(1).merged


def test_merged_admin_centers_nodes_are_marked(session, tables):
    session.add(tables.osm_polygon(id=1, osm_id=1337, wikidata="Q42", all_tags={"name:en": "Zurich"}))
    session.add(tables.osm_point(id=1, osm_id=43, all_tags={"name:ch": "Züri"}, wikidata="Q42"))
    session.add(tables.osm_relation_member(member_id=43, member_type=0, role="admin_center", osm_id=1337))
    session.commit()

    merge_nodes_linked_by_relation()

    assert session.query(tables.osm_point).get(1).merged


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


def test_merged_label_nodes_are_marked(session, tables):
    session.add(tables.osm_polygon(id=1, osm_id=1337, all_tags={"name:en": "Zurich"}))
    session.add(tables.osm_relation_member(member_id=43, member_type=0, role="label", osm_id=1337))
    session.add(tables.osm_point(id=1, osm_id=43, all_tags={"name:ch": "Züri"}, wikipedia="de:Zürich", wikidata="Q47"))
    session.commit()

    merge_nodes_linked_by_relation()

    assert session.query(tables.osm_point).get(1).merged


def test_attributes_from_political_nodes_are_added_to_polygon(session, tables):
    session.add(tables.osm_polygon(id=1, osm_id=-5396194, all_tags={"name:en": "Washington D.C."}))
    session.add(tables.osm_relation_member(member_id=158368533, member_type=0, role="Political", osm_id=-5396194))
    session.add(tables.osm_point(osm_id=158368533, all_tags={"name:de": "Washington"}, wikipedia="en:Washington"))
    session.commit()

    merge_nodes_linked_by_relation()

    assert session.query(tables.osm_polygon).get(1).all_tags == {"name:en": "Washington D.C.", "name:de": "Washington"}
    assert session.query(tables.osm_polygon).get(1).wikipedia == "en:Washington"
    assert session.query(tables.osm_polygon).get(1).merged_osm_id == 158368533


def test_nodes_with_different_wiki_refs_are_not_merged(session, tables):
    session.add(tables.osm_point(id=1, osm_id=32, all_tags={"name:en": "EqualName"}, wikipedia="en:equalname"))
    session.add(tables.osm_relation_member(member_id=32, member_type=0, role="admin_center", osm_id=-101))
    session.add(tables.osm_polygon(id=1, osm_id=-101, all_tags={"name:en": "EqualName"}, wikipedia="en:differentwiki"))
    session.commit()

    merge_nodes_linked_by_relation()

    assert session.query(tables.osm_polygon).get(1).merged_osm_id is None
    assert not session.query(tables.osm_point).get(1).merged
