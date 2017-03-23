import os
from helpers.database import exec_sql, psql_exec, exists


def run():
    exists_query = "SELECT 1 AS result FROM pg_database WHERE datname='{}'".format(os.getenv("DB_NAME"))
    if exists(exists_query, user="postgres", database="postgres"):
        print("skip database init, since it is already initialized")
        return

    create_hstore_extension()
    create_database()
    create_database_functions()


def create_hstore_extension():
    exec_sql("CREATE EXTENSION hstore;", user="postgres", database="template_postgis")


def create_database():
    create_user_query = "CREATE USER {} WITH PASSWORD '{}';".format(os.getenv("DB_USER"),
                                                                    os.getenv("DB_PASSWORD"))
    create_database_query = "CREATE DATABASE {} WITH TEMPLATE template_postgis OWNER {};".format(
            os.getenv("DB_NAME"),
            os.getenv("DB_USER")
            )

    exec_sql(create_user_query, user="postgres", database="postgres")
    exec_sql(create_database_query, user="postgres", database="postgres")


def create_database_functions():
    psql_exec("functions.sql", cwd=os.path.dirname(__file__))
