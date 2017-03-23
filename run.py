#!/usr/bin/python

import os
import time
import cProfile
import datetime

from osmnames.init_database import init_database
from osmnames.import_wikipedia import import_wikipedia
from osmnames.import_osm import import_osm
from osmnames.export_osmnames import export_osmnames


while os.system("psql --username=postgres postgres -c 'select 1'"):
    print("waiting for postgresql")
    time.sleep(2)


profiler = cProfile.Profile()
profiler.enable()

init_database.run()
import_wikipedia.run()
import_osm.run()
export_osmnames.run()

timestamp = datetime.datetime.now().strftime('%Y_%m_%d-%H%M')
profiler.dump_stats("data/logs/{}.cprofile".format(timestamp))
