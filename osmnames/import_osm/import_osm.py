import os
from subprocess import check_call
from osmnames.helpers.database import psql_exec, exec_sql_from_file
from osmnames import settings
from osmnames.import_osm.prepare_housenumbers import prepare_housenumbers


def import_osm():
    download_pbf()
    import_pbf_file()
    create_helper_tables()
    create_functions()
    prepare_imported_data()


def download_pbf():
    if settings.get("PBF_FILE"):
        print "skip pbf download since PBF_FILE env is defined: {}".format(settings.get("PBF_FILE"))
        return

    url = settings.get("PBF_URL")
    destination_dir = settings.get("IMPORT_DIR")
    check_call(["wget", "--no-clobber", "--directory-prefix", destination_dir, url])


def import_pbf_file():
    import_dir = settings.get("IMPORT_DIR")
    pbf_filename = settings.get("PBF_FILE") or settings.get("PBF_URL").split('/')[-1]
    pbf_filepath = import_dir + pbf_filename

    imposm_connection = "postgis://{user}@{host}/{db_name}".format(
        user=settings.get("DB_USER"),
        host=settings.get("DB_HOST"),
        db_name=settings.get("DB_NAME"),
        )

    check_call([
        "imposm3", "import",
        "-connection", imposm_connection,
        "-mapping", "{}/mapping.yml".format(settings.get("IMPORT_DIR")),
        "-dbschema-import", settings.get("DB_SCHEMA"),
        "-read", pbf_filepath,
        "-write",
        "-overwritecache",
    ])


def create_helper_tables():
    create_country_name_table()
    create_osm_grid_table()


def create_country_name_table():
    # does not work with exec_sql_from_file
    psql_exec("country_name.sql", cwd="{}/sql/".format(settings.get("DATA_DIR")))


def create_osm_grid_table():
    # does not work with exec_sql_from_file
    psql_exec("country_osm_grid.sql", cwd="{}/sql/".format(settings.get("DATA_DIR")))


def create_functions():
    exec_sql_from_file("functions.sql", cwd=os.path.dirname(__file__))


def prepare_imported_data():
    delete_unusable_entries()
    ranking_partitioning()
    determine_linked_places()
    create_hierarchy()
    merge_corresponding_streets()
    prepare_housenumbers()


def delete_unusable_entries():
    exec_sql_from_file("01_delete_unusable_entries.sql", cwd=os.path.dirname(__file__))


def ranking_partitioning():
    exec_sql_from_file("02_ranking_partitioning.sql", cwd=os.path.dirname(__file__))


def determine_linked_places():
    exec_sql_from_file("03_determine_linked_places.sql", cwd=os.path.dirname(__file__))


def create_hierarchy():
    # does not work with exec_sql_from_file
    psql_exec("04_create_hierarchy.sql", cwd=os.path.dirname(__file__))


def merge_corresponding_streets():
    exec_sql_from_file("05_merge_corresponding_streets.sql", cwd=os.path.dirname(__file__))
