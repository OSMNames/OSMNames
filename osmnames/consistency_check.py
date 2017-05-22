from osmnames import logger
from osmnames.database.functions import count

log = logger.setup(__name__)


def missing_country_codes():
    missing = count("SELECT COUNT(id) FROM osm_elements_view WHERE country_code = '' IS NOT FALSE")
    if missing > 0:
        log.warning('{} elements with missing country_code'.format(missing))


def missing_parent_ids():
    missing = count("SELECT COUNT(id) FROM osm_elements_view WHERE parent_id IS NULL")
    if missing > 0:
        log.warning('{} elements with missing parent_id'.format(missing))


def missing_street_ids():
    missing = count("SELECT COUNT(id) FROM osm_housenumber WHERE street_id IS NULL")
    if missing > 0:
        log.warning('{} housenumbers with missing street_id'.format(missing))
