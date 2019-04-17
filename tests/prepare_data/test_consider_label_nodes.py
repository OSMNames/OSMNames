from osmnames.prepare_data.prepare_data import consider_label_nodes


def test_attributes_from_label_nodes_are_added_to_polygon(session, tables):
    session.add(tables.osm_polygon(id=1, osm_id=1337, all_tags={"name:en": "Zurich"}))
    session.add(tables.osm_relation_member(member_id=43, member_type=0, role="label", osm_id=1337))
    session.add(tables.osm_point(osm_id=43, all_tags={"name:ch": "Züri"}, wikipedia="de:Zürich", wikidata="Q47"))
    session.commit()

    consider_label_nodes()

    assert session.query(tables.osm_polygon).get(1).all_tags == {"name:en": "Zurich", "name:ch": "Züri"}
    assert session.query(tables.osm_polygon).get(1).wikipedia == "de:Zürich"
    assert session.query(tables.osm_polygon).get(1).wikidata == "Q47"
