from osmnames import logger
from osmnames.database.functions import count

log = logger.setup(__name__)


def missing_country_codes():
    missing = count("SELECT COUNT(id) FROM osm_polygon WHERE place_rank >= 4 AND country_code = '' IS NOT FALSE")
    if missing > 0:
        log.warning('{} polygons (place_rank >= 4) with missing country_code'.format(missing))


def missing_parent_ids():
    missing_linestrings = count("SELECT COUNT(id) FROM osm_linestring WHERE parent_id IS NULL")
    if missing_linestrings > 0:
        log.warning('{} linestrings with missing parent_id'.format(missing_linestrings))

    missing_polygons = count("SELECT COUNT(id) FROM osm_polygon WHERE place_rank > 4 AND parent_id IS NULL")
    if missing_polygons > 0:
        log.warning('{} polygons (place_rank > 4) with missing parent_id'.format(missing_polygons))

    missing_points = count("SELECT COUNT(id) FROM osm_point WHERE parent_id IS NULL")
    if missing_points > 0:
        log.warning('{} points with missing parent_id'.format(missing_points))

    missing_housenumbers = count("SELECT COUNT(id) FROM osm_housenumber WHERE parent_id IS NULL")
    if missing_housenumbers > 0:
        log.warning('{} housenumbers with missing parent_id'.format(missing_housenumbers))


def missing_street_ids():
    missing = count("SELECT COUNT(id) FROM osm_housenumber WHERE street_id IS NULL")
    if missing > 0:
        log.warning('{} housenumbers with missing street_id'.format(missing))
