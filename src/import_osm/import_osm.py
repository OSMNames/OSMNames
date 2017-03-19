import glob
import os
from subprocess import check_call
from shared.helpers import psql_exec


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


def initalize_helper_tables():
    data_dir = os.getenv("DATA_DIR")

    psql_exec("{}/sql/country_name.sql".format(data_dir), user="postgres")
    psql_exec("{}/sql/count_osm_grid.sql".format(data_dir), user="postgres")
    psql_exec("00_index_helper_tables.sql")


def prepare_imported_data():
    psql_exec("01_delete_unusable_entries.sql")
    psql_exec("02_ranking_partitioning.sql")
    psql_exec("03_determine_linked_places.sql")
    psql_exec("04_create_hierarchy.sql")
    psql_exec("05_merge_corresponding_streets.sql")


def run():
    import_pbf_files()
    initalize_helper_tables()
    prepare_imported_data()
