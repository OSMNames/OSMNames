import pytest
import os

from geoalchemy2.elements import WKTElement
from osmnames.database.functions import exec_sql_from_file
from osmnames.import_osm.create_hierarchy import set_parent_id_for_polygons_intersecting_multiple_polygons


@pytest.fixture(scope="function")
def schema(engine):
    current_directory = os.path.dirname(os.path.realpath(__file__))
    exec_sql_from_file('../fixtures/test_prepare_imported_data.sql.dump', cwd=current_directory)


def test_parent_id_is_set_to_most_overlapping_polygon(session, schema, tables):
    session.add(
            tables.osm_polygon(
                id=1,
                osm_id=-1684266,
                name="Benzenschwil",
                type="administrative",
                admin_level=9,
                geometry=WKTElement("""POLYGON((929603.928183161 5982466.6111572,930365.816502139
                    5983926.44348676,932711.26320228 5982077.22286048,930426.195409627
                    5981070.44707183,929603.928183161 5982466.6111572))""", srid=3857)
            )
        )

    session.add(
            tables.osm_polygon(
                id=2,
                osm_id=-1684376,
                name="Muehlau",
                type="administrative",
                admin_level=8,
                geometry=WKTElement("""POLYGON((932032.520679103 5980887.71055006,933069.51511899
                    5982719.0425116,935929.764085068 5982048.34587089,934320.378348639
                    5977868.24265717,932727.451952781 5978260.51975435,932032.520679103
                    5980887.71055006))""", srid=3857)
            )
        )

    session.add(
            tables.osm_polygon(
                id=3,
                osm_id=-1684316,
                name="Geltwil",
                type="administrative",
                admin_level=8,
                geometry=WKTElement("""POLYGON((924663.52274994 5983140.77662277,926684.308024323
                    5984470.7594462,929629.550263205 5982320.6400434,925598.849970542
                    5981292.49285415,924663.52274994 5983140.77662277))""", srid=3857)
            )
        )

    session.commit()

    set_parent_id_for_polygons_intersecting_multiple_polygons()

    assert session.query(tables.osm_polygon).get(1).parent_id == 2


def test_most_overlapping_polygon_ignored_if_admin_level_lower(session, schema, tables):
    session.add(
            tables.osm_polygon(
                id=1,
                osm_id=-1684266,
                name="Benzenschwil",
                type="administrative",
                admin_level=9,
                geometry=WKTElement("""POLYGON((929603.928183161 5982466.6111572,930365.816502139
                    5983926.44348676,932711.26320228 5982077.22286048,930426.195409627
                    5981070.44707183,929603.928183161 5982466.6111572))""", srid=3857)
            )
        )

    session.add(
            tables.osm_polygon(
                id=2,
                osm_id=-1684376,
                name="Muehlau",
                type="administrative",
                admin_level=10,
                geometry=WKTElement("""POLYGON((932032.520679103 5980887.71055006,933069.51511899
                    5982719.0425116,935929.764085068 5982048.34587089,934320.378348639
                    5977868.24265717,932727.451952781 5978260.51975435,932032.520679103
                    5980887.71055006))""", srid=3857)
            )
        )

    session.commit()

    set_parent_id_for_polygons_intersecting_multiple_polygons()

    assert session.query(tables.osm_polygon).get(1).parent_id is None
