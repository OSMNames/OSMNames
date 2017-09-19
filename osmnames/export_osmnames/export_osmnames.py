import os
import gzip
import shutil
from subprocess import check_call
from osmnames.database.functions import exec_sql, exec_sql_from_file
from osmnames import settings


def export_osmnames():
    create_functions()
    create_indexes()
    create_views()
    export_geonames()
    export_housenumbers()
    gzip_tsv_files()


def create_functions():
    exec_sql_from_file("functions.sql", cwd=os.path.dirname(__file__))


def create_indexes():
    exec_sql("CREATE INDEX osm_housenumber_street_id ON osm_housenumber(street_id);")


def create_views():
    create_polygons_view()
    create_points_view()
    create_linestrings_view()
    create_merged_linestrings_view()
    create_geonames_view()
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


def create_geonames_view():
    exec_sql_from_file("create_geonames_view.sql", cwd=os.path.dirname(__file__))


def export_geonames():
    export_to_tsv("SELECT * FROM geonames_view ORDER BY importance DESC NULLS LAST", geonames_export_path())


def export_housenumbers():
    export_to_tsv("SELECT * FROM mv_housenumbers", housenumbers_export_path())


def export_to_tsv(query, path):
    check_call([
        "psql",
        "-c", "COPY ({}) TO STDOUT WITH DELIMITER '\t' CSV HEADER".format(query),
        "-o", path,
        settings.get("DB_USER"),
        settings.get("DB_NAME"),
        ])


def gzip_tsv_files():
    for tsv_file_path in [geonames_export_path(), housenumbers_export_path()]:
        with open(tsv_file_path, 'rb') as f_in, gzip.open("{}.gz".format(tsv_file_path), 'wb') as f_out:
            shutil.copyfileobj(f_in, f_out)


def geonames_export_path():
    return "{}{}_geonames.tsv".format(settings.get("EXPORT_DIR"), imported_pbf_filename())


def housenumbers_export_path():
    return "{}{}_housenumbers.tsv".format(settings.get("EXPORT_DIR"), imported_pbf_filename())


def imported_pbf_filename():
    filename_with_suffix = settings.get("PBF_FILE") or settings.get("PBF_FILE_URL").split('/')[-1]
    return filename_with_suffix.split(".")[0]
