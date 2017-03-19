import download_pbf
from init_database import init_database
from import_osm import import_osm


download_pbf.run()
init_database.run()
import_osm.run()
