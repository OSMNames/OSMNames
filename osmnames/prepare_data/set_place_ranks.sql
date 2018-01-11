/* See Nominatim functions.sql placex_insert() line 676 for determining ranks
   Reference: https://github.com/openstreetmap/Nominatim/blob/master/sql/functions.sql */
DROP FUNCTION IF EXISTS get_place_rank(TEXT, INT);
CREATE FUNCTION get_place_rank(type TEXT, admin_level INT DEFAULT NULL)
RETURNS int AS $$
BEGIN
  RETURN CASE
    WHEN type IN ('administrative') THEN 2* COALESCE(admin_level,15)
    WHEN type IN ('continent', 'sea', 'ocean') THEN 2
    WHEN type IN ('country') THEN 4
    WHEN type IN ('state') THEN 8
    WHEN type IN ('county') THEN 12
    WHEN type IN ('city', 'water', 'desert') THEN 16
    WHEN type IN ('island', 'bay', 'river') THEN 17
    WHEN type IN ('region', 'peak', 'volcano') THEN 18
    WHEN type IN ('town') THEN 18
    WHEN type IN ('village','hamlet','municipality','district','unincorporated_area','borough') THEN 19
    WHEN type IN ('suburb','subdivision','isolated_dwelling','farm','locality','islet','mountain_pass','hill') THEN 20
    WHEN type IN ('neighbourhood', 'residential','reservoir','stream') THEN 22
    WHEN type IN ('motorway','trunk','primary','secondary','tertiary','unclassified','residential','road','living_street','raceway','construction','track','crossing','riverbank','canal') THEN 26
    WHEN type IN ('motorway_link','trunk_link','primary_link','secondary_link','tertiary_link','service','path','cycleway','steps','bridleway','footway','corridor','pedestrian') THEN 27
    WHEN type IN ('houses') THEN 28
    ELSE 30
  END;
END;
$$ LANGUAGE plpgsql IMMUTABLE;


UPDATE osm_polygon SET place_rank = get_place_rank(type, admin_level);
UPDATE osm_linestring SET place_rank = get_place_rank(type, admin_level);
UPDATE osm_point SET place_rank = get_place_rank(type, admin_level);
