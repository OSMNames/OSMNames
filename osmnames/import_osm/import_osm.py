import os

from subprocess import check_call
from osmnames.database.functions import exec_sql, psql_exec, exec_sql_from_file, vacuum_database
from osmnames import settings
from osmnames.import_osm.prepare_housenumbers import prepare_housenumbers
from osmnames import consistency_check


def import_osm():
    download_pbf()
    sanatize_for_import()
    import_pbf_file()
    create_custom_columns()
    create_osm_elements_view() 
    create_helper_tables()
    prepare_imported_data()


def download_pbf():
    if settings.get("PBF_FILE"):
        print "skip pbf download since PBF_FILE env is defined: {}".format(settings.get("PBF_FILE"))
        return

    url = settings.get("PBF_FILE_URL")
    destination_dir = settings.get("IMPORT_DIR")
    check_call(["wget", "--no-clobber", "--directory-prefix", destination_dir, url])


def sanatize_for_import():
    exec_sql('DROP TABLE IF EXISTS osm_linestring, osm_point, osm_polygon, osm_housenumber CASCADE')


def import_pbf_file():
    import_dir = settings.get("IMPORT_DIR")
    pbf_filename = settings.get("PBF_FILE") or settings.get("PBF_FILE_URL").split('/')[-1]
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


def create_custom_columns():
    exec_sql_from_file("create_custom_columns.sql", cwd=os.path.dirname(__file__))


def create_osm_elements_view():
    exec_sql_from_file("create_osm_elements_view.sql", cwd=os.path.dirname(__file__))


def create_helper_tables():
    create_country_name_table()
    create_osm_grid_table()


def create_country_name_table():
    # does not work with exec_sql_from_file
    psql_exec("country_name.sql", cwd="{}/sql/".format(settings.get("DATA_DIR")))


def create_osm_grid_table():
    # does not work with exec_sql_from_file
    psql_exec("country_osm_grid.sql", cwd="{}/sql/".format(settings.get("DATA_DIR")))


def prepare_imported_data():
    delete_unusable_entries()
    set_place_ranks()
    set_country_codes()
    determine_linked_places()
    create_hierarchy()
    merge_corresponding_streets()
    prepare_housenumbers()
    vacuum_database()


def delete_unusable_entries():
    exec_sql_from_file("delete_unusable_entries.sql", cwd=os.path.dirname(__file__))


def set_place_ranks():
    exec_sql_from_file("set_place_ranks.sql", cwd=os.path.dirname(__file__))


def set_country_codes():
    exec_sql_from_file("set_country_codes.sql", cwd=os.path.dirname(__file__))
    consistency_check.missing_country_codes()


def determine_linked_places():
    exec_sql_from_file("determine_linked_places.sql", cwd=os.path.dirname(__file__))


def create_hierarchy():
    exec_sql_from_file("create_hierarchy.sql", cwd=os.path.dirname(__file__))
    consistency_check.missing_parent_ids()


def merge_corresponding_streets():
    exec_sql_from_file("merge_corresponding_streets.sql", cwd=os.path.dirname(__file__))
