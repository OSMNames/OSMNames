import os

DB_HOST = 'postgres'
DB_NAME = 'osm'
DB_USER = 'osm'
DB_PASSWORD = 'osm'
DB_SCHEMA = 'public'

DATA_DIR = '/osmnames/data/'
IMPORT_DIR = '/osmnames/data/import/'
EXPORT_DIR = '/osmnames/data/export/'
CACHE_DIR = '/osmnames/data/cache/'

PBF_FILE = os.getenv('PBF_FILE', '')
PBF_FILE_URL = os.getenv('PBF_FILE_URL', '')
# credits to nominatim for providing the precalculated data
WIKIPEDIA_DUMP_URL = 'http://www.nominatim.org/data/wikipedia_article.sql.bin'
