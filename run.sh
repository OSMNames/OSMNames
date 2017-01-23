#!/bin/bash

set -e

docker-compose build

if [ ! -f ./data/switzerland-latest.osm.pbf ] ; then
    wget --directory-prefix=./data http://download.geofabrik.de/europe/switzerland-latest.osm.pbf
fi

docker-compose up -d postgres
sleep 10 # wait for the DB to be up

for COMMAND in 'import-wikipedia' 'schema' 'import-osm' 'export-osmnames'
do
    docker-compose run --rm $COMMAND
done
