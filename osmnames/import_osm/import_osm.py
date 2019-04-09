import os
from osmnames.database.functions import exec_sql, exec_sql_from_file
from osmnames import settings
from osmnames import logger
from osmnames.logger import logged_check_call

log = logger.setup(__name__)


def import_osm():
    download_pbf()
    sanatize_for_import()
    import_pbf_file()
    import_country_names()
    import_country_osm_grid()


def download_pbf():
    if settings.get("PBF_FILE"):
        log.info("skip pbf download since PBF_FILE env is defined: {}".format(settings.get("PBF_FILE")))
        return

    url = settings.get("PBF_FILE_URL")
    destination_dir = settings.get("IMPORT_DIR")
    logged_check_call(["wget", "--no-clobber", "--directory-prefix", destination_dir, url])


def sanatize_for_import():
    exec_sql("""DROP TABLE IF EXISTS osm_linestring,
                                     osm_point,
                                     osm_polygon,
                                     osm_housenumber CASCADE""")


def import_pbf_file():
    import_dir = settings.get("IMPORT_DIR")
    pbf_filename = settings.get("PBF_FILE") or settings.get("PBF_FILE_URL").split('/')[-1]
    pbf_filepath = import_dir + pbf_filename

    imposm_connection = "postgis://{user}@{host}/{db_name}".format(
        user=settings.get("DB_USER"),
        host=settings.get("DB_HOST"),
        db_name=settings.get("DB_NAME"),
        )

    logged_check_call([
        "imposm", "import",
        "-connection", imposm_connection,
        "-mapping", "{}/mapping.yml".format(os.path.dirname(__file__)),
        "-dbschema-import", settings.get("DB_SCHEMA"),
        "-read", pbf_filepath,
        "-write",
        "-overwritecache",
    ])


def import_country_names():
    exec_sql_from_file("country_name.sql", cwd="{}/sql/".format(settings.get("DATA_DIR")))


def import_country_osm_grid():
    exec_sql_from_file("country_osm_grid.sql", cwd="{}/sql/".format(settings.get("DATA_DIR")))
