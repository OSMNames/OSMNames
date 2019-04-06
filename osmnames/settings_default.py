import os

DB_HOST = 'postgres'
DB_NAME = 'osm'
DB_USER = 'osm'
DB_PASSWORD = 'osm'
DB_SCHEMA = 'public'
SKIP_VACUUM = os.getenv('SKIP_VACUUM', False)
VACUUM_JOBS = os.getenv('VACUUM_JOBS', 4)
SKIP_WIKIPEDIA = os.getenv('SKIP_WIKIPEDIA', False)

DATA_DIR = '/osmnames/data/'
IMPORT_DIR = '/osmnames/data/import/'
EXPORT_DIR = '/osmnames/data/export/'

PBF_FILE = os.getenv('PBF_FILE', '')
PBF_FILE_URL = os.getenv('PBF_FILE_URL', '')
# credits to nominatim for providing the precalculated data
WIKIPEDIA_DUMP_URL = 'http://www.nominatim.org/data/wikipedia_article.sql.bin'
WIKIPEDIA_REDIRECTS_DUMP_URL = 'https://www.nominatim.org/data/wikipedia_redirect.sql.bin'
