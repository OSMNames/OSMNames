import os
import psycopg2
from subprocess import check_call


def psql_exec(file_path, user=os.getenv('PGUSER'), cwd=""):
    check_call([
            "psql",
            "--username={}".format(user),
            "--file={}/{}".format(cwd, file_path)
        ]
    )


def exec_sql(sql, user=os.getenv('PGUSER'), database=os.getenv('DB_NAME')):
    connection = _connection(user=user, database=database)
    connection.set_session(autocommit=True)
    connection.cursor().execute(sql)


def exists(query, user=os.getenv('PGUSER'), database=os.getenv('DB_NAME')):
    cursor = _connection(user=user, database=database).cursor()
    cursor.execute("SELECT EXISTS({});".format(query))
    return cursor.fetchone()[0]


def _connection(user, database):
    return psycopg2.connect("user={} dbname={}".format(user, database))
