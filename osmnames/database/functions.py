import os
import time
import psycopg2
import re
import tempfile

from subprocess import check_call
from osmnames import settings
from osmnames import logger

log = logger.setup(__name__)


def exec_sql_from_file(filename, user=settings.get("DB_USER"), database=settings.get("DB_NAME"), cwd="", parallelize=False):
    log.info("start executing sql file {}".format(filename))
    start = time.time()

    path = os.path.join(cwd, filename)
    shared_args = [
        "-v", "ON_ERROR_STOP=1",
        "--username={}".format(user),
        "--dbname={}".format(database),
    ]

    if parallelize:
        with open(path, "r") as f:
            sql = f.read()

        with tempfile.NamedTemporaryFile(encoding="utf-8", mode="w", prefix="OSMNames", suffix=".sql") as fp:
            fp.write(modify_sql_with_auto_modulo(sql))
            fp.flush()
            check_call(
                ["par_psql", *shared_args, "--file={}".format(fp.name)],
                stdout=open(os.devnull, 'w')
            )
    else:
        check_call(
            ["psql", *shared_args, "--file={}".format(path)],
            stdout=open(os.devnull, 'w')
        )

    end = time.time()
    log.info("finished executing sql file {} (took {}s)"
             .format(filename, round(end-start, 1)))


def modify_sql_with_auto_modulo(sql):
    return re.sub(
        r"""
            (UPDATE[^;]+?)         # query starting at UPDATE keyword
            auto_modulo\(          # beginning of auto_modulo function
                ([A-Z0-9a-z._\s]+) # column name to calculate modulo on
            \)                     # closing paren of function
            ([^;]*);               # rest of query until ;
            \s*(?:--\&)?           # optionally eat --& comment
        """,
        """
            \g<1>auto_modulo(\g<2>, 8, 0)\g<3>; --&
            \g<1>auto_modulo(\g<2>, 8, 1)\g<3>; --&
            \g<1>auto_modulo(\g<2>, 8, 2)\g<3>; --&
            \g<1>auto_modulo(\g<2>, 8, 3)\g<3>; --&
            \g<1>auto_modulo(\g<2>, 8, 4)\g<3>; --&
            \g<1>auto_modulo(\g<2>, 8, 5)\g<3>; --&
            \g<1>auto_modulo(\g<2>, 8, 6)\g<3>; --&
            \g<1>auto_modulo(\g<2>, 8, 7)\g<3>; --&
        """,
        sql,
        flags=re.VERBOSE
    )


def exec_sql(sql, user=settings.get('DB_USER'), database=settings.get('DB_NAME')):
    connection = psycopg2.connect(user=user, dbname=database)
    connection.set_session(autocommit=True)
    cursor = connection.cursor()
    cursor.execute(sql)
    return cursor


def exists(query, user=settings.get('DB_USER'), database=settings.get('DB_NAME')):
    return exec_sql("SELECT EXISTS({});".format(query), user, database).fetchone()[0]


def count(query, user=settings.get('DB_USER'), database=settings.get('DB_NAME')):
    return exec_sql(query, user, database).fetchone()[0]


def vacuum_database():
    if settings.get('SKIP_VACUUM'):
        return

    log.info("start vacuum database")
    start = time.time()

    check_call([
            "vacuumdb",
            "--username=postgres",
            "--dbname={}".format(settings.get("DB_NAME")),
            "--analyze",
            "--jobs={}".format(settings.get('VACUUM_JOBS')),
        ], stdout=open(os.devnull, 'w')
    )

    end = time.time()
    log.info("finished vacuum database (took {}s)"
             .format(round(end-start, 1)))


def wait_for_database():
    while os.system("psql --username=postgres postgres -c 'select 1' > /dev/null 2>&1"):
        print("waiting for postgresql")
        time.sleep(2)
