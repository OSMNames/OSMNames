import os
import gzip
import shutil
from subprocess import check_call
from osmnames.database.functions import exec_sql_from_file
from osmnames import settings


EXPORT_FILE_PATH = "{}/export.tsv".format(settings.get("EXPORT_DIR"))
HOUSENUMBERS_EXPORT_FILE_PATH = "{}/housenumbers.tsv".format(settings.get("EXPORT_DIR"))


def export_osmnames():
    create_functions()
    create_views()
    export_tsv()
    export_housenumbers()
    gzip_tsv()


def create_functions():
    exec_sql_from_file("functions.sql", cwd=os.path.dirname(__file__))


def create_views():
    create_polygons_view()
    create_points_view()
    create_linestrings_view()
    create_merged_linestrings_view()
    create_housenumbers_view()


def create_polygons_view():
    exec_sql_from_file("create_polygons_view.sql", cwd=os.path.dirname(__file__))


def create_points_view():
    exec_sql_from_file("create_points_view.sql", cwd=os.path.dirname(__file__))


def create_linestrings_view():
    exec_sql_from_file("create_linestrings_view.sql", cwd=os.path.dirname(__file__))


def create_merged_linestrings_view():
    exec_sql_from_file("create_merged_linestrings_view.sql", cwd=os.path.dirname(__file__))


def create_housenumbers_view():
    exec_sql_from_file("create_housenumbers_view.sql", cwd=os.path.dirname(__file__))


def export_tsv():
    export_sql_filepath = "{}/export.sql".format(os.path.dirname(__file__))
    check_call(["pgclimb", "-f", export_sql_filepath,
                           "-o", EXPORT_FILE_PATH,
                           "--host", settings.get("DB_HOST"),
                           "--dbname", settings.get("DB_NAME"),
                           "--username", settings.get("DB_USER"),
                           "--pass", settings.get("DB_PASSWORD"),
                           "tsv", "--header"])


def export_housenumbers():
    check_call(["pgclimb", "-c", "SELECT * FROM mv_housenumbers;",
                           "-o", HOUSENUMBERS_EXPORT_FILE_PATH,
                           "--host", settings.get("DB_HOST"),
                           "--dbname", settings.get("DB_NAME"),
                           "--username", settings.get("DB_USER"),
                           "--pass", settings.get("DB_PASSWORD"),
                           "tsv", "--header"])


def gzip_tsv():
    with open(EXPORT_FILE_PATH, 'rb') as f_in, gzip.open("{}.gz".format(EXPORT_FILE_PATH), 'wb') as f_out:
            shutil.copyfileobj(f_in, f_out)
