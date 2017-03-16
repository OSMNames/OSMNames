import glob
import os
from subprocess import check_call
from shared.helpers import psql_exec


def import_pbf_files(path):
    pbf_files = glob.glob("%s/*.pbf".format(path))

    if len(pbf_files) == 0:
        raise IOError('No PBF files for import found in path %s.'.format(path))

    for pbf_file in pbf_files:
        import_pbf_file(pbf_file)


def import_pbf_file(pbf_file):
    imposm_connection = "postgis://{1}:{2}/{3}".format(os.getenv('PGUSER'),
                                                       os.getenv('PGHOST'),
                                                       os.getenv('DB_NAME'))

    check_call(["imposm3 import", "-conection {1}".format(imposm_connection),
                                  "-overwritecache",
                                  "-mapping mapping.yml",
                                  "-cachedir {1}".format(os.getenv('CACHEDIR')),
                                  "-dbschema-import {1}".format(os.getenv('DB_SCHEMA')),
                                  "-read {1}".format(pbf_file)])


def initalize_helper_tables():
    data_dir = os.getenv('DATADIR')

    psql_exec("{1}/sql/country_name.sql".format(data_dir), user="postgres")
    psql_exec("{1}/sql/count_osm_grid.sql".format(data_dir), user="postgres")
    psql_exec("00_index_helper_tables.sql")


def prepare_imported_data():
    psql_exec("01_delete_unusable_entries.sql")
    psql_exec("02_ranking_partitioning.sql")
    psql_exec("03_determine_linked_places.sql")
    psql_exec("04_create_hierarchy.sql")
    psql_exec("05_merge_corresponding_streets.sql")
