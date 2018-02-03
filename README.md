# OSM Names [![Build Status](https://travis-ci.org/OSMNames/OSMNames.svg?branch=master)](https://travis-ci.org/OSMNames/OSMNames) [![Documentation Status](https://readthedocs.org/projects/osmnames-development-branch/badge/?version=latest)](http://osmnames.readthedocs.io/en/latest/?badge=latest)

Database of geographic place names with hierarchy and bounding boxes from
OpenStreetMap for full text search downloadable for free: http://osmnames.org

## Target of OSM Names

- Downloadable gazeteer data a la GeoNames.org: http://download.geonames.org/export/dump/ but each record has bounding box and an importance rank known from Nominatim
- Data are derived primarily from OpenStreetMap
- The data format is simple to use tab-delimited text in utf8 encoding (as geonames.org). First line has column names.
- Different type of records are stored in different files (download and index just what you need, sometimes you don't need POIs or addresses with house numbers)
- Possible to generate from a country specific extract of Open Street Map (together with vector tiles)

## Benefits of OSM Names

- Direct indexing via fulltext search engines (SphinxSearch, ElasticSearch, etc.)
- Simple process to get a **basic** search in place names on a map within minutes
- Downloading the basic gazeteer data from OSM in usable format is problematic now (a need to process large OSM Planet files)

## Sample search server

- Powered by super fast open-source fulltext Sphinxsearch - inspired by Swiss GeoAdmin search service
- JSON/JSONP API similar to Nominatim: nominatim.openstreetmap.org
- Ready to use via Docker in minutes
- https://github.com/klokantech/osmnames-sphinxsearch
- http://osmnames.org

## Data format of tsv export of OSMNames

Details about the output format of OSMNames can be found in the
[documentation](http://osmnames.readthedocs.io/en/latest/introduction.html#output-format).

## Data

The world extract can be downloaded here:
https://github.com/geometalab/OSMNames/releases/download/v2.0/planet-latest_geonames.tsv.gz

https://github.com/geometalab/OSMNames/releases/download/v2.0/planet-latest_housenumbers.tsv.gz


If you want to extract only the information for a specific country, you can use the following command

```
awk -F $'\t' 'BEGIN {OFS = FS}{if (NR!=1) {  if ($16 =="[country_code]")  { print}    } else {print}}' planet-latest.tsv > countryExtract.tsv
```
where country_code is the ISO-3166 2-letter country code.


## Get Started

The OSM PBF data dump will be download when starting the process. By default it
will download the entire world. If you want to change this, edit the `.env`
file and change `PBF_FILE_URL`. Alternatively, you can manually place a PBF
file in the `data/import` directory and define `PBF_FILE` with the filename.
(For example, to process only a specific country you can use the PBF-files from
`http://download.geofabrik.de/index.html`)

We can now start the process with:
```bash
docker-compose run --rm osmnames
```

This will call the script `src/run.py` in the docker container, which will execute following steps:
* Initialize the database
* Download the pbf
* Download and import the wikipedia dump
* Import the pbf file to the database
* Export names and their bounding boxes to a TSV datasets

If you run the command a second time, some steps will be skipped. To run it
from scratch, remove the postgres container, which will destroy the database.

```bash
docker-compose kill postgres
docker-compose rm postgres
```

The process will create a file `<import-file-name>_geonames.tsv` with all the
geonames and `<import-file-name>_housenumbers.tsv` with the house numbers. To
use the export with osmnames-sphinxsearch, have a look at the corresponding
[section in the
readme](https://github.com/klokantech/osmnames-sphinxsearch#usage-of-docker-image).
A simple command to get started is:

```bash
docker run --rm --name klokantech-osmnames-sphinxsearch -v `pwd`/planet-latest_geonames.tsv.gz:/data/input/data.tsv.gz -p 80:80 klokantech/osmnames-sphinxsearch
```
Afterwards you can access the web interface in a browser with `http://localhost`.

## Development

### Tests

To run the tests execute following command:
```
docker-compose run --rm osmnames bash run_tests.sh
```

### SQL Style Guide

To have a consistent style of SQL code, try to follow this guideline: http://www.sqlstyle.guide/


## More Documentation

The full documentation of the project can be found here: http://osmnames.readthedocs.io/en/latest/.
