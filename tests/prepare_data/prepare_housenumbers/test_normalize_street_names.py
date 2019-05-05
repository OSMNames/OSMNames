# -*- coding: utf-8 -*-

from osmnames.prepare_data.prepare_housenumbers import normalize_street_names


def test_normalize_housenumber_streets(session, tables):
    session.add(tables.osm_housenumber(id=1, street="Bietinger Weg"))

    session.commit()

    normalize_street_names()

    assert str(session.query(tables.osm_housenumber).get(1).normalized_street) == "bietingerweg"


def test_normalize_linestring_names(session, tables):
    session.add(tables.osm_linestring(id=1, name="Bietinger Weg"))

    session.commit()

    normalize_street_names()

    assert str(session.query(tables.osm_linestring).get(1).normalized_name) == "bietingerweg"


def test_remove_dashes(session, tables):
    session.add(tables.osm_linestring(id=1, name="Chemin du Pra-de-Villars"))

    session.commit()

    normalize_street_names()

    assert str(session.query(tables.osm_linestring).get(1).normalized_name) == "chemindupradevillars"


def test_remove_accents(session, tables):
    session.add(tables.osm_linestring(id=1, name="Cité Préville"))

    session.commit()

    normalize_street_names()

    assert str(session.query(tables.osm_linestring).get(1).normalized_name) == "citepreville"


def test_remove_quotes(session, tables):
    session.add(tables.osm_linestring(id=1, name="Grand'Rue"))

    session.commit()

    normalize_street_names()

    assert str(session.query(tables.osm_linestring).get(1).normalized_name) == "grandrue"


def test_remove_dots_and_brackets(session, tables):
    session.add(tables.osm_linestring(id=1, name="Grand.Rue(FR)"))

    session.commit()

    normalize_street_names()

    assert str(session.query(tables.osm_linestring).get(1).normalized_name) == "grandruefr"
