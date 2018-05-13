from geoalchemy2.elements import WKTElement
from osmnames.prepare_data.prepare_housenumbers import set_street_attributes_by_nearest_street


def test_street_id_and_name_set_to_nearest_street_with_same_parent(session, tables):
    session.add(
            tables.osm_housenumber(
                    id=1,
                    osm_id=195916994,
                    housenumber=89,
                    parent_id=9999,
                    geometry=WKTElement("""POLYGON((835220.293672307 5939566.85419046,835223.11154127
                    5939588.79287532,835237.163563318 5939586.97376781,835234.345694356
                    5939565.06244245,835220.293672307 5939566.85419046))""", srid=3857)
                )
            )

    session.add(
            tables.osm_linestring(
                    id=2,
                    osm_id=25736914,
                    name="Dorfstrasse",
                    parent_id=9999,
                    geometry=WKTElement("""LINESTRING(835569.625447532 5939578.46636778,835353.853196615
                        5939540.30626715,835189.782309692 5939547.66472518,834976.622652515
                        5939499.47924756,834903.040815942 5939518.99686424,834783.579967145
                        5939588.61506781,834755.821158649 5939590.92656582)""", srid=3857)
                )
            )

    session.add(
            tables.osm_linestring(
                    id=3,
                    osm_id=26162329,
                    name="Zaelgli",
                    parent_id=9999,
                    geometry=WKTElement("""LINESTRING(835139.891099933 5939534.73955675,835080.034711193
                        5939629.44250458,835054.655229139 5939807.33473233)""", srid=3857)
                )
            )

    session.commit()

    set_street_attributes_by_nearest_street()

    assert session.query(tables.osm_housenumber).get(1).street_id == 25736914
    assert str(session.query(tables.osm_housenumber).get(1).street) == "Dorfstrasse"
