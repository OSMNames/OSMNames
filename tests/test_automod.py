from osmnames.database.functions import modify_sql_with_auto_modulo


def test_modify_sql_with_auto_modulo():
    assert clean(modify_sql_with_auto_modulo("""
            UPDATE foo SET bar = baz WHERE auto_modulo(id);
        """, 8)) == clean("""
            UPDATE foo SET bar = baz WHERE auto_modulo(id, 8, 0); --&
            UPDATE foo SET bar = baz WHERE auto_modulo(id, 8, 1); --&
            UPDATE foo SET bar = baz WHERE auto_modulo(id, 8, 2); --&
            UPDATE foo SET bar = baz WHERE auto_modulo(id, 8, 3); --&
            UPDATE foo SET bar = baz WHERE auto_modulo(id, 8, 4); --&
            UPDATE foo SET bar = baz WHERE auto_modulo(id, 8, 5); --&
            UPDATE foo SET bar = baz WHERE auto_modulo(id, 8, 6); --&
            UPDATE foo SET bar = baz WHERE auto_modulo(id, 8, 7); --&
        """)


def test_modify_sql_with_auto_module_with_newlines():
    assert clean(modify_sql_with_auto_modulo("""
            UPDATE osm_polygon AS polygon
            SET merged_osm_id = linked_node_osm_id,
                all_tags = polygon.all_tags || linked_node_tags,
                wikipedia = COALESCE(NULLIF(polygon.wikipedia, ''), linked_node_wikipedia),
                wikidata = COALESCE(NULLIF(polygon.wikidata, ''), linked_node_wikidata)
            FROM polygons_with_linked_by_relation_node
            WHERE polygon_id = polygon.id AND auto_modulo(polygon.id);
        """, 8)).startswith(clean("""
            UPDATE osm_polygon AS polygon
            SET merged_osm_id = linked_node_osm_id,
                all_tags = polygon.all_tags || linked_node_tags,
                wikipedia = COALESCE(NULLIF(polygon.wikipedia, ''), linked_node_wikipedia),
                wikidata = COALESCE(NULLIF(polygon.wikidata, ''), linked_node_wikidata)
            FROM polygons_with_linked_by_relation_node
            WHERE polygon_id = polygon.id AND auto_modulo(polygon.id, 8, 0); --&
        """))


def test_modify_sql_with_auto_modulo_ignores_normal_update_queries():
    query = """
    UPDATE osm_polygon AS polygon
      SET merged_osm_id = linked_node_osm_id,
          all_tags = polygon.all_tags || linked_node_tags,
          wikipedia = COALESCE(NULLIF(polygon.wikipedia, ''), linked_node_wikipedia),
          wikidata = COALESCE(NULLIF(polygon.wikidata, ''), linked_node_wikidata)
      FROM polygons_with_linked_by_relation_node
      WHERE polygon_id = polygon.id;
    """

    assert modify_sql_with_auto_modulo(query, 8) == query


def clean(str):
    return "\n".join(line.strip() for line in str.strip().splitlines())
