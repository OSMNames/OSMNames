SELECT r.name,
    classify_road_railway(r.type, r.service) AS class,
    r.type,
    ST_X(topoint(ST_Transform(r.geometry, 4326))) AS lon,
    ST_Y(topoint(ST_Transform(r.geometry, 4326))) AS lat,
    ST_XMIN(ST_Transform(r.geometry, 4326)) AS west,
    ST_YMIN(ST_Transform(r.geometry, 4326)) AS south,
    ST_XMAX(ST_Transform(r.geometry, 4326)) AS east,
    ST_YMAX(ST_Transform(r.geometry, 4326)) AS north
FROM osm_road_linestring AS r;
