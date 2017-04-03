import psycopg2
from subprocess import check_call
from osmnames import settings


def psql_exec(filepath, user=settings.get("DB_USER"), cwd=""):
    check_call([
            "psql",
            "--username={}".format(user),
            "--dbname={}".format(settings.get("DB_NAME")),
            "--file={}/{}".format(cwd, filepath)
        ]
    )


def exec_sql_from_file(filename, user=settings.get("DB_USER"), database=settings.get("DB_NAME"), cwd=""):
    file_path = "{}/{}".format(cwd, filename)
    connection = psycopg2.connect(user=user, dbname=database)
    connection.set_session(autocommit=True)
    connection.cursor().execute(open(file_path, "r").read())


def exec_sql(sql, user=settings.get('DB_USER'), database=settings.get('DB_NAME')):
    connection = psycopg2.connect(user=user, dbname=database)
    connection.set_session(autocommit=True)
    connection.cursor().execute(sql)


def exists(query, user=settings.get('DB_USER'), database=settings.get('DB_NAME')):
    connection = psycopg2.connect(user=user, dbname=database)
    cursor = connection.cursor()
    cursor.execute("SELECT EXISTS({});".format(query))
    return cursor.fetchone()[0]
