from osmnames.prepare_data.prepare_housenumbers import set_street_names_by_relation_attributes


def test_name_is_set_when_street_relation_exists(session, tables):
    session.add(tables.osm_housenumber(id=1, osm_id=1))
    session.add(tables.osm_relation(osm_id=-1, type="street", street="Oberfeldring"))
    session.add(tables.osm_relation_member(osm_id=-1, member_id=1))

    session.commit()

    set_street_names_by_relation_attributes()

    assert str(session.query(tables.osm_housenumber).get(1).street) == "Oberfeldring"


def test_name_is_set_when_associatedStreet_relation_exists(session, tables):
    session.add(tables.osm_housenumber(id=1, osm_id=1))
    session.add(tables.osm_relation(osm_id=-1, type="associatedStreet", street="Bahnhofstrasse"))
    session.add(tables.osm_relation_member(osm_id=-1, member_id=1))

    session.commit()

    set_street_names_by_relation_attributes()

    assert str(session.query(tables.osm_housenumber).get(1).street) == "Bahnhofstrasse"


def test_name_is_set_when_street_relation_with_name_instead_street_exists(session, tables):
    session.add(tables.osm_housenumber(id=1, osm_id=1))
    session.add(tables.osm_relation(osm_id=-1, type="street", name="Oberfeldring", street=""))
    session.add(tables.osm_relation_member(osm_id=-1, member_id=1))

    session.commit()

    set_street_names_by_relation_attributes()

    assert str(session.query(tables.osm_housenumber).get(1).street) == "Oberfeldring"


def test_name_is_NOT_set_when_street_already_set(session, tables):
    session.add(tables.osm_housenumber(id=1, osm_id=1, street="Oberfeldring"))
    session.add(tables.osm_relation(osm_id=-1, type="street", name=""))
    session.add(tables.osm_relation_member(osm_id=-1, member_id=1))

    session.commit()

    set_street_names_by_relation_attributes()

    assert str(session.query(tables.osm_housenumber).get(1).street) == "Oberfeldring"
