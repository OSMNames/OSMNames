#!/bin/bash

set -e

echo "###########################"
echo "BUILDING IMAGES"
docker-compose build
echo "DONE BUILDING"
echo "###########################"


if [ ! -f ./data/switzerland-latest.osm.pbf ] ; then
  echo "###########################"
  echo "DOWNLOADING PBF"
  wget --directory-prefix=./data http://download.geofabrik.de/europe/switzerland-latest.osm.pbf
  echo "DONE DOWNLOADING"
  echo "###########################"
fi

echo "###########################"
echo "Removing old containers"
docker-compose down -v
echo "DONE STARTING"
echo "###########################"

echo "###########################"
echo "STARTING THE DATABASE"
docker-compose up -d postgres
sleep 10 # wait for the DB to be up
echo "DONE STARTING"
echo "###########################"

for COMMAND in 'import-wikipedia' 'schema' 'import-osm' 'export-osmnames'
do
    echo "###########################"
    echo "RUNNING $COMMAND"
    docker-compose run --rm $COMMAND
    echo "DONE $COMMAND"
    echo "###########################"
done
