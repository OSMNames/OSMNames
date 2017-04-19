#!/usr/bin/python

import cProfile
import datetime

from osmnames.database.functions import wait_for_database
from osmnames.init_database.init_database import init_database
from osmnames.import_wikipedia.import_wikipedia import import_wikipedia
from osmnames.import_osm.import_osm import import_osm
from osmnames.export_osmnames.export_osmnames import export_osmnames


wait_for_database()

profiler = cProfile.Profile()
profiler.enable()

init_database()
import_wikipedia()
import_osm()
export_osmnames()

timestamp = datetime.datetime.now().strftime('%Y_%m_%d-%H%M')
profiler.dump_stats("data/logs/{}.cprofile".format(timestamp))
