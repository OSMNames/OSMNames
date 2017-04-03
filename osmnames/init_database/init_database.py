import os
from osmnames.helpers.database import exec_sql, exec_sql_from_file, exists
from osmnames import settings


def init_database():
    exists_query = "SELECT 1 AS result FROM pg_database WHERE datname='{}'".format(settings.get("DB_NAME"))
    if exists(exists_query, user="postgres", database="postgres"):
        print("skip database init, since it is already initialized")
        return

    create_hstore_extension()
    create_database()
    create_database_functions()


def create_hstore_extension():
    exec_sql("CREATE EXTENSION IF NOT EXISTS hstore;", user="postgres", database="template_postgis")


def create_database():
    create_user_query = "CREATE USER {} WITH PASSWORD '{}';".format(settings.get("DB_USER"),
                                                                    settings.get("DB_PASSWORD"))
    create_database_query = "CREATE DATABASE {} WITH TEMPLATE template_postgis OWNER {};".format(
            settings.get("DB_NAME"),
            settings.get("DB_USER")
            )

    exec_sql(create_user_query, user="postgres", database="postgres")
    exec_sql(create_database_query, user="postgres", database="postgres")


def create_database_functions():
    exec_sql_from_file("functions.sql", cwd=os.path.dirname(__file__))
