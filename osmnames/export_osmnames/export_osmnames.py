import os
import gzip
import shutil
from subprocess import check_call
from osmnames.helpers.database import exec_sql_from_file
from osmnames import settings


def run():
    create_functions()
    prepare_data()
    export_tsv()
    gzip_tsv()


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
                           "-o", _export_filepath(),
                           "--host", settings.get("DB_HOST"),
                           "--dbname", settings.get("DB_NAME"),
                           "--username", settings.get("DB_USER"),
                           "--pass", settings.get("DB_PASSWORD"),
                           "tsv", "--header"])


def gzip_tsv():
    with open(_export_filepath(), 'rb') as f_in, gzip.open(_export_filepath() + ".gz", 'wb') as f_out:
            shutil.copyfileobj(f_in, f_out)


def _export_filepath():
    return "{}/export.tsv".format(settings.get("EXPORT_DIR"))
