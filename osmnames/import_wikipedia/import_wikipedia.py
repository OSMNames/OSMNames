from osmnames.database.functions import exec_sql, exists
from osmnames import settings
from osmnames import logger
from osmnames.logger import logged_check_call
from osmnames.helpers import run_in_parallel

log = logger.setup(__name__)


def import_wikipedia():
    if exists("SELECT * FROM information_schema.tables WHERE table_name='wikipedia_article'"):
        log.info("skip wikipedia import, since table already exists")
        return

    if settings.get("SKIP_WIKIPEDIA"):
        log.info("SKIP_WIKIPEDIA = True in .env file, therefore skipping import and only create basic scaffolding")
        create_basic_scaffolding()
        return

    download_dump(settings.get("WIKIPEDIA_DUMP_URL"))
    download_dump(settings.get("WIKIPEDIA_REDIRECTS_DUMP_URL"))
    restore_wikipedia_dumps()

    run_in_parallel(
        prepare_wikipedia_redirects,
        create_wikipedia_index
    )


def download_dump(url):
    destination_dir = settings.get("IMPORT_DIR")
    logged_check_call(["wget", "--no-clobber", "--directory-prefix", destination_dir, url])


def restore_wikipedia_dumps():
    _create_temporary_user_for_dump()

    article_dump_filename = settings.get("WIKIPEDIA_DUMP_URL").split("/")[-1]
    article_dump_path = "{}/{}".format(settings.get("IMPORT_DIR"), article_dump_filename)

    redirect_dump_filename = settings.get("WIKIPEDIA_REDIRECTS_DUMP_URL").split("/")[-1]
    redirect_dump_path = "{}/{}".format(settings.get("IMPORT_DIR"), redirect_dump_filename)

    logged_check_call(["pg_restore", "-j", "2", "--dbname", "osm", "-U", "brian", article_dump_path])
    logged_check_call(["pg_restore", "-j", "2", "--dbname", "osm", "-U", "brian", redirect_dump_path])

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
        ALTER TABLE wikipedia_redirect OWNER TO {username};
    """.format(username=settings.get("DB_USER"))

    exec_sql(query, user="postgres")


def prepare_wikipedia_redirects():
    exec_sql("DROP INDEX idx_wikipedia_redirect_from_title")
    exec_sql("""
        UPDATE wikipedia_redirect
            SET from_title = concat_ws(':', language, from_title),
                to_title = concat_ws(':', language, to_title);
    """)
    exec_sql("CREATE INDEX ON wikipedia_redirect(from_title)")


def create_wikipedia_index():
    exec_sql("CREATE INDEX idx_wikipedia_article_title ON wikipedia_article (title);")


# this function should only be used, when the wikipedia import is skipped
# it creates minimal scaffolding which is expected in the further processing
def create_basic_scaffolding():
    query = """
        CREATE TABLE wikipedia_article (
            language text NOT NULL,
            title text NOT NULL,
            importance double precision
        );

        CREATE TABLE wikipedia_redirect (
            language text,
            from_title text NOT NULL,
            to_title text NOT NULL
        );
    """

    exec_sql(query)
