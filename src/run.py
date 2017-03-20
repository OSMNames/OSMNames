from init_database import init_database
from import_wikipedia import import_wikipedia
from import_osm import import_osm
from export_osmnames import export_osmnames


init_database.run()
import_wikipedia.run()
import_osm.run()
export_osmnames.run()
