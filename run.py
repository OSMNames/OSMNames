#!/usr/bin/python3

import cProfile
import datetime

from osmnames.database.functions import wait_for_database
from osmnames.init_database.init_database import init_database
from osmnames.import_wikipedia.import_wikipedia import import_wikipedia
from osmnames.import_osm.import_osm import import_osm
from osmnames.prepare_data.prepare_data import prepare_data
from osmnames.export_osmnames.export_osmnames import export_osmnames


wait_for_database()

profiler = cProfile.Profile()
started_at = datetime.datetime.now()
profiler.enable()

init_database()
import_wikipedia()
import_osm()
prepare_data()
export_osmnames()

profiler.dump_stats("data/logs/{}.cprofile".format(started_at.strftime('%Y_%m_%d-%H%M')))
