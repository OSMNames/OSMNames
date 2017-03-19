import glob
import os
from subprocess import check_call
from shared.helpers import psql_exec


def run():
    import_pbf_files()
    create_helper_tables()
    create_functions()
    prepare_imported_data()


def import_pbf_files():
    import_dir = os.getenv("IMPORT_DIR")
    pbf_files = glob.glob("{}/*.pbf".format(import_dir))

    if len(pbf_files) == 0:
        raise IOError("No PBF files for import found in path {}.".format(import_dir))

    for pbf_file in pbf_files:
        import_pbf_file(pbf_file)


def import_pbf_file(pbf_file):
    imposm_connection = "postgis://{}@{}/{}".format(os.getenv("PGUSER"),
                                                    os.getenv("PGHOST"),
                                                    os.getenv("DB_NAME"))

    check_call(["imposm3", "import",
                           "-connection", imposm_connection,
                           "-mapping", "{}/mapping.yml".format(os.getenv("IMPORT_DIR")),
                           "-dbschema-import", os.getenv("DB_SCHEMA"),
                           "-read", pbf_file,
                           "-write",
                           "-overwritecache"])


def create_helper_tables():
    create_country_name_table()
    create_osm_grid_table()


def create_country_name_table():
    psql_exec("country_name.sql", cwd="{}/sql/".format(os.getenv("DATA_DIR")))


def create_osm_grid_table():
    psql_exec("country_osm_grid.sql", cwd="{}/sql/".format(os.getenv("DATA_DIR")))


def create_functions():
    psql_exec("functions.sql", cwd=os.path.dirname(__file__))


def prepare_imported_data():
    delete_unusable_entries()
    ranking_partitioning()
    determine_linked_places()
    create_hierarchy()
    merge_corresponding_streets()


def delete_unusable_entries():
    psql_exec("01_delete_unusable_entries.sql", cwd=os.path.dirname(__file__))


def ranking_partitioning():
    psql_exec("02_ranking_partitioning.sql", cwd=os.path.dirname(__file__))


def determine_linked_places():
    psql_exec("03_determine_linked_places.sql", cwd=os.path.dirname(__file__))


def create_hierarchy():
    psql_exec("04_create_hierarchy.sql", cwd=os.path.dirname(__file__))


def merge_corresponding_streets():
    psql_exec("05_merge_corresponding_streets.sql", cwd=os.path.dirname(__file__))
