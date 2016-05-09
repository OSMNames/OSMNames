SELECT r.name,
    city_class(r.type) AS class,
    r.type AS type,
    ST_X(ST_PointOnSurface(ST_Transform(r.geometry, 4326))) AS lon,
    ST_Y(ST_PointOnSurface(ST_Transform(r.geometry, 4326))) AS lat,
    r.rank_search AS place_rank,
    0.75-(cast(r.rank_search as float)/40) AS importance,  
    array_to_string(getHierarchyAsTextArray(r.parent_ids), ', ', '*') AS display_name,  
    ST_XMIN(ST_Transform(r.geometry, 4326)) AS west,
    ST_YMIN(ST_Transform(r.geometry, 4326)) AS south,
    ST_XMAX(ST_Transform(r.geometry, 4326)) AS east,
    ST_YMAX(ST_Transform(r.geometry, 4326)) AS north
FROM osm_city_polygon AS r;
