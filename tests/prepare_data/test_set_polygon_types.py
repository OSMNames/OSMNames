from osmnames.prepare_data.prepare_data import set_polygon_types


def test_polygon_type_is_updated_when_mapping_exists(session, tables):
    session.add(tables.osm_polygon(id=1, country_code='ch', admin_level=8, type='administrative'))
    session.add(tables.admin_level_type_mapping(country_code='ch', admin_level=8, type='city'))
    session.commit()

    set_polygon_types()

    assert session.query(tables.osm_polygon).get(1).type == 'city'


def test_polygon_type_is_not_updated_when_type_not_administrative(session, tables):
    session.add(tables.osm_polygon(id=1, country_code='ch', admin_level=8, type='city'))
    session.add(tables.admin_level_type_mapping(country_code='ch', admin_level=8, type='state'))
    session.commit()

    set_polygon_types()

    assert session.query(tables.osm_polygon).get(1).type == 'city'
