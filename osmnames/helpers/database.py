import psycopg2
from osmnames import settings


def psql_exec(filename, user=settings.get("DB_USER"), database=settings.get("DB_NAME"), cwd=""):
    file_path = "{}/{}".format(cwd, filename)
    connection = _connection(user=user, database=database)
    connection.set_session(autocommit=True)
    connection.cursor().execute(open(file_path, "r").read())


def exec_sql(sql, user=settings.get('DB_USER'), database=settings.get('DB_NAME')):
    connection = _connection(user=user, database=database)
    connection.set_session(autocommit=True)
    connection.cursor().execute(sql)


def exists(query, user=settings.get('DB_USER'), database=settings.get('DB_NAME')):
    cursor = _connection(user=user, database=database).cursor()
    cursor.execute("SELECT EXISTS({});".format(query))
    return cursor.fetchone()[0]


def _connection(user, database):
    return psycopg2.connect("user={} dbname={}".format(user, database))
