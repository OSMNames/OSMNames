import os
from subprocess import check_call
from helpers.database import psql_exec, exec_sql, exists


def run():
    if exists("SELECT * FROM information_schema.tables WHERE table_name='wikipedia_article'"):
        print("skip wikipedia import, since table already exists")
        return

    download_wikipedia_dump()
    restore_wikipedia_dump()
    create_wikipedia_index()

    psql_exec("create_index.sql", cwd=os.path.dirname(__file__))


def download_wikipedia_dump():
    url = os.getenv("WIKIPEDIA_DUMP_URL")
    destination_dir = os.getenv("IMPORT_DIR")
    check_call(["wget", "--no-clobber", "--directory-prefix", destination_dir, url])


def restore_wikipedia_dump():
    _create_temporary_user_for_dump()

    dump_filename = os.getenv("WIKIPEDIA_DUMP_URL").split("/")[-1]
    dump_path = "{}/{}".format(os.getenv("IMPORT_DIR"), dump_filename)

    check_call(["pg_restore", "--dbname", "osm", "-U", "brian", dump_path])

    _drop_temporary_user_for_dump()


def _create_temporary_user_for_dump():
    query = """
        CREATE ROLE brian LOGIN PASSWORD 'brian';
        GRANT ALL PRIVILEGES ON DATABASE {database} to brian;
    """.format(database=os.getenv("DB_NAME"))

    exec_sql(query, user="postgres")


def _drop_temporary_user_for_dump():
    query = """
        ALTER TABLE wikipedia_article OWNER TO {username};
        DROP ROLE brian;
    """.format(username=os.getenv("DB_USER"))

    exec_sql(query, user="postgres")


def create_wikipedia_index():
    exec_sql("CREATE INDEX idx_wikipedia_article_language_title ON wikipedia_article (language,title);")
