from subprocess import check_call
from osmnames.helpers.database import exec_sql, exists
from osmnames import settings


def import_wikipedia():
    if exists("SELECT * FROM information_schema.tables WHERE table_name='wikipedia_article'"):
        print("skip wikipedia import, since table already exists")
        return

    download_wikipedia_dump()
    restore_wikipedia_dump()
    create_wikipedia_index()


def download_wikipedia_dump():
    url = settings.get("WIKIPEDIA_DUMP_URL")
    destination_dir = settings.get("IMPORT_DIR")
    check_call(["wget", "--no-clobber", "--directory-prefix", destination_dir, url])


def restore_wikipedia_dump():
    _create_temporary_user_for_dump()

    dump_filename = settings.get("WIKIPEDIA_DUMP_URL").split("/")[-1]
    dump_path = "{}/{}".format(settings.get("IMPORT_DIR"), dump_filename)

    check_call(["pg_restore", "-j", "2", "--dbname", "osm", "-U", "brian", dump_path])

    _alter_wikipedia_dump_owner()


def _create_temporary_user_for_dump():
    query = """
        CREATE ROLE brian LOGIN PASSWORD 'brian';
        GRANT ALL PRIVILEGES ON DATABASE {database} to brian;
    """.format(database=settings.get("DB_NAME"))

    exec_sql(query, user="postgres")


def _alter_wikipedia_dump_owner():
    query = """
        ALTER TABLE wikipedia_article OWNER TO {username};
    """.format(username=settings.get("DB_USER"))

    exec_sql(query, user="postgres")


def create_wikipedia_index():
    exec_sql("CREATE INDEX idx_wikipedia_article_language_title ON wikipedia_article (language,title);")
