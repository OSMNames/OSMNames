import os
import gzip
import shutil
from subprocess import check_call
from osmnames.helpers.database import exec_sql_from_file
from osmnames import settings


EXPORT_FILE_PATH = "{}/export.tsv".format(settings.get("EXPORT_DIR"))
HOUSENUMBERS_EXPORT_FILE_PATH = "{}/housenumbers.tsv".format(settings.get("EXPORT_DIR"))


def export_osmnames():
    create_functions()
    prepare_data()
    export_tsv()
    export_housenumbers()
    gzip_tsv()


def export_housenumbers():
    check_call(["pgclimb", "-c", "SELECT * FROM osm_housenumbers;",
                           "-o", HOUSENUMBERS_EXPORT_FILE_PATH,
                           "--host", settings.get("DB_HOST"),
                           "--dbname", settings.get("DB_NAME"),
                           "--username", settings.get("DB_USER"),
                           "--pass", settings.get("DB_PASSWORD"),
                           "tsv", "--header"])


def create_functions():
    exec_sql_from_file("functions.sql", cwd=os.path.dirname(__file__))


def prepare_data():
    collect_polygons()
    collect_points()
    collect_linestrings()
    collect_merged_linestrings()


def collect_polygons():
    exec_sql_from_file("01_polygons.sql", cwd=os.path.dirname(__file__))


def collect_points():
    exec_sql_from_file("02_points.sql", cwd=os.path.dirname(__file__))


def collect_linestrings():
    exec_sql_from_file("03_linestrings.sql", cwd=os.path.dirname(__file__))


def collect_merged_linestrings():
    exec_sql_from_file("04_merged_linestrings.sql", cwd=os.path.dirname(__file__))


def export_tsv():
    export_sql_filepath = "{}/export.sql".format(os.path.dirname(__file__))
    check_call(["pgclimb", "-f", export_sql_filepath,
                           "-o", EXPORT_FILE_PATH,
                           "--host", settings.get("DB_HOST"),
                           "--dbname", settings.get("DB_NAME"),
                           "--username", settings.get("DB_USER"),
                           "--pass", settings.get("DB_PASSWORD"),
                           "tsv", "--header"])


def gzip_tsv():
    with open(EXPORT_FILE_PATH, 'rb') as f_in, gzip.open(EXPORT_FILE_PATH, 'wb') as f_out:
            shutil.copyfileobj(f_in, f_out)
