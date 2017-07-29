# -*- coding: utf-8 -*-

import os
import pytest

from osmnames.database.functions import exec_sql_from_file
from osmnames.import_osm.prepare_housenumbers import normalize_street_names


@pytest.fixture(scope="function")
def schema(engine):
    current_directory = os.path.dirname(os.path.realpath(__file__))
    exec_sql_from_file('../fixtures/test_prepare_imported_data.sql.dump', cwd=current_directory)


def test_normalize_housenumber_streets(session, schema, tables):
    session.add(tables.osm_housenumber(id=1, street="Bietinger Weg"))

    session.commit()

    normalize_street_names()

    assert str(session.query(tables.osm_housenumber).get(1).normalized_street) == "bietingerweg"


def test_normalize_linestring_names(session, schema, tables):
    session.add(tables.osm_linestring(id=1, name="Bietinger Weg"))

    session.commit()

    normalize_street_names()

    assert str(session.query(tables.osm_linestring).get(1).normalized_name) == "bietingerweg"


def test_remove_dashes(session, schema, tables):
    session.add(tables.osm_linestring(id=1, name="Chemin du Pra-de-Villars"))

    session.commit()

    normalize_street_names()

    assert str(session.query(tables.osm_linestring).get(1).normalized_name) == "chemindupradevillars"


def test_remove_accents(session, schema, tables):
    session.add(tables.osm_linestring(id=1, name="Cité Préville"))

    session.commit()

    normalize_street_names()

    assert str(session.query(tables.osm_linestring).get(1).normalized_name) == "citepreville"


def test_remove_quotes(session, schema, tables):
    session.add(tables.osm_linestring(id=1, name="Grand'Rue"))

    session.commit()

    normalize_street_names()

    assert str(session.query(tables.osm_linestring).get(1).normalized_name) == "grandrue"
