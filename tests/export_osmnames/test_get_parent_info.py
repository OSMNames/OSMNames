import pytest
import os

from osmnames.database.functions import exec_sql_from_file
from osmnames.export_osmnames.export_osmnames import create_functions

@pytest.fixture(scope="function")
def schema(engine):
    current_directory = os.path.dirname(os.path.realpath(__file__))
    exec_sql_from_file('fixtures/test_export_osmnames.sql.dump', cwd=current_directory)
    create_functions()


def test_get_parent_info_1(session, schema, tables):

    session.add(
            tables.osm_polygon(
                id=1,
                name="a small lake",
                type="water",
                place_rank=16,
                parent_id=2
            )
        )

    session.add(
            tables.osm_polygon(
                id=2,
                name="a village",
                type="administrative",
                place_rank=19,
                parent_id=3
            )
        )

    session.add(
            tables.osm_polygon(
                id=3,
                name="a town",
                type="administrative",
                place_rank=18,
                parent_id=4
            )
        )    

    session.add(
        tables.osm_polygon(
            id=4,
            name="a city",
            type="administrative",
            place_rank=16,
            parent_id=5
        )
    )

    session.add(
        tables.osm_polygon(
            id=5,
            name="a county",
            type="administrative",
            place_rank=12,
            parent_id=6
        )
    )


    session.add(
        tables.osm_polygon(
            id=6,
            name="a state",
            type="administrative",
            place_rank=8,
            parent_id=7
        )
    )   


    session.add(
        tables.osm_polygon(
            id=7,
            name="a country",
            type="administrative",
            place_rank=4
        )
    )
    session.commit()

    parent_info = get_parent_info(session, 1, "")

    assert parent_info[0] == "a state"              # state
    assert parent_info[1] == "a county"             # county
    assert parent_info[2] == "a city"               # city
    assert parent_info[3] == "a small lake, a village, a town, a city, a county, a state, a country" # display_name


def test_get_parent_info_2(session, schema, tables):

    session.add(
            tables.osm_linestring(
                id=1,
                name="Halkova",
                place_rank=26,
                parent_id=2
            )
        )

    session.add(
            tables.osm_polygon(
                id=2,
                name="Rakovnik",
                type="administrative",
                place_rank=16,
                parent_id=3
            )
        )

    session.add(
            tables.osm_polygon(
                id=3,
                name="Okres Rakovnik",
                type="administrative",
                place_rank=14,
                parent_id=4
            )
        )    

    session.add(
        tables.osm_polygon(
            id=4,
            name="Stredocesky kraj",
            type="administrative",
            place_rank=12,
            parent_id=5
        )
    )

    session.add(
        tables.osm_polygon(
            id=5,
            name="Czech Republic",
            type="administrative",
            place_rank=4
        )
    )   
    session.commit()

    parent_info = get_parent_info(session, 2, "Halkova")

    assert parent_info[0] == "Stredocesky kraj"    # state
    assert parent_info[1] == "Okres Rakovnik"      # county
    assert parent_info[2] == "Rakovnik"            # city
    assert parent_info[3] == "Halkova, Rakovnik, Okres Rakovnik, Stredocesky kraj, Czech Republic"  # display_name


def test_get_parent_info_3(session, schema, tables):

    session.add(
            tables.osm_linestring(
                id=1,
                name="Oberseestrasse",
                place_rank=26,
                parent_id=2
            )
        )

    session.add(
            tables.osm_polygon(
                id=2,
                name="Rapperswil-Jona",
                type="administrative",
                place_rank=16,
                parent_id=3
            )
        )

    session.add(
            tables.osm_polygon(
                id=3,
                name="Wahlkreis See-Gaster",
                type="administrative",
                place_rank=12,
                parent_id=4
            )
        )    

    session.add(
        tables.osm_polygon(
            id=4,
            name="Sankt Gallen",
            type="administrative",
            place_rank=8,
            parent_id=5
        )
    )

    session.add(
        tables.osm_polygon(
            id=5,
            name="Switzerland",
            type="administrative",
            place_rank=4
        )
    )   
    session.commit()

    parent_info = get_parent_info(session, 2, "Oberseestrasse")

    assert parent_info[0] == "Sankt Gallen"             # state
    assert parent_info[1] == "Wahlkreis See-Gaster"     # county
    assert parent_info[2] == "Rapperswil-Jona"          # city
    assert parent_info[3] == "Oberseestrasse, Rapperswil-Jona, Wahlkreis See-Gaster, Sankt Gallen, Switzerland" # display_name


def test_city_name_gets_set(session, schema, tables):

    session.add(
            tables.osm_polygon(
                id=1,
                name="Jona",
                type="administrative",
                place_rank=16
            )
        )
    session.commit()

    parent_info = get_parent_info(session, 1, "")
    assert parent_info[2] == "Jona"


def get_parent_info(session, id, name):
    query = "SELECT get_parent_info({},'{}')".format(id, name)
    parent_info = session.execute(query).fetchone()[0].strip('(').strip(')').split(',')
    parent_info = [x.strip('"') for x in parent_info]
    parent_info[3] = ",".join(parent_info[3:])
    return parent_info
    