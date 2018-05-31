from osmnames.database.functions import exec_sql_from_file
from osmnames.prepare_data.set_names import set_names_from_tags


def test_name_get_set_from_all_tags(session, tables):
    session.add(tables.osm_polygon(id=1, name="", all_tags={"name:en": "Zurich"}))
    session.add(tables.osm_linestring(id=1, name="", all_tags={"name:de": "Rhein"}))
    session.commit()

    set_names_from_tags()

    assert session.query(tables.osm_polygon).get(1).name == "Zurich"
    assert session.query(tables.osm_linestring).get(1).name == "Rhein"


def test_name_get_set_according_to_priority(session, tables):
    # Where priority order is en, local_language, fr, de, es, ru, zh

    session.add(
      tables.osm_polygon(
          id=2,
          name="",
          all_tags={"name": "Lac Leman", "name:de": "Genfersee"}
        )
    )
    session.add(
      tables.osm_linestring(
          id=2,
          name="",
          all_tags={"name:es": "Rin", "name:it": "Reno", "name:de": "Rhein"}
        )
    )
    session.commit()
    set_names_from_tags()

    assert session.query(tables.osm_polygon).get(2).name == "Lac Leman"
    assert session.query(tables.osm_linestring).get(2).name == "Rhein"


def test_alternative_names_get_set(session, tables):
    session.add(
        tables.osm_point(
            id=1,
            all_tags={"name:de": "Matterhorn", "name:fr": "Cervin", "name:it": "Cervino"}
        )
    )
    session.commit()
    set_names_from_tags()

    alternative_names = session.query(tables.osm_point).get(1).alternative_names

    assert all(x in alternative_names for x in ["Matterhorn", "Cervin", "Cervino"])


def test_alternative_names_do_not_contain_name(session, tables):
    session.add(
        tables.osm_point(
            id=2,
            name="Matterhorn",
            all_tags={"name:de": "Matterhorn", "name:fr": "Cervin", "name:it": "Cervino"}
        )
    )
    session.commit()
    set_names_from_tags()

    assert "Matterhorn" not in session.query(tables.osm_point).get(2).alternative_names


def test_alternative_names_do_not_contain_duplicates(session, tables):
    session.add(
        tables.osm_point(
            id=3,
            name="Matterhorn",
            all_tags={"name:fr": "Cervin", "name:it": "Cervino", "alt_name": "Cervino"}
        )
    )
    session.commit()
    set_names_from_tags()

    assert session.query(tables.osm_point).get(3).alternative_names.count("Cervino") == 1


def test_alternative_names_are_null_if_only_name_is_present(session, tables):
    session.add(
        tables.osm_point(
            id=4,
            name="Matterhorn"
        )
    )
    session.commit()
    set_names_from_tags()

    assert session.query(tables.osm_point).get(4).alternative_names is None


def test_tabs_get_deleted_from_name(session, tables):
    session.add(
        tables.osm_polygon(
            id=3,
            name="Lake\t\tZurich"
            )
        )
    session.commit()
    set_names_from_tags()

    assert session.query(tables.osm_polygon).get(3).name == "Lake Zurich"


def test_tabs_get_deleted_from_alternative_names(session, tables):
    session.add(
        tables.osm_polygon(
            id=4,
            name='Bodensee',
            all_tags={"name:en": "Lake         Constance", "name:fr": "Lac\tde\tConstance"}
            )
        )
    session.commit()
    set_names_from_tags()

    assert session.query(tables.osm_polygon).get(4).alternative_names.count('\t') == 0
