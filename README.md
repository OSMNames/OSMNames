# OSM Names Database of geographic place names from OpenStreetMap for full text search downloadable for free. Website: http://osmnames.org
Does include hierarchy information without house numbers or zip codes.

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
- osmnames.klokantech.com/

## Data format of tsv export of OSMNames

| Column            | Description |
| -------------     | ------------- |
| id                | internal identifier
| name              | the name of the feature (default language is en, others available(de,es,fr,ru,zh))
| alternative_names | all other available and distinct names separated by commas
| osm_type          | the osm type of this feature (node, way, relation)
| osm_id            |
| class             |
| type              |
| lon               |
| lat               |
| place_rank        | rank from 1-30 ascending depending on the type and class
| importance        | importance [0.0-1.0] depending on wikipedia
| street            |
| city              |
| county            |
| state             |
| country           |
| country_code      | ISO-3166 2-letter country code
| display_name      | the display name representing the hierarchy
| west              | bbox
| south             | bbox
| east              | bbox
| north             | bbox
| wikidata          | the wikidata associated with this feature
| wikipedia         | the wikipedia URL associated with this feature

REMARKs:
* Fields like housenumber and postalcode don't belong to this dataset.

## Data

The world extract can be downloaded here:
https://github.com/geometalab/OSMNames/releases/download/v1.1/planet-latest.tsv.gz


If you want to extract only the information for a specific country, you can use the following command

```
awk -F $'\t' 'BEGIN {OFS = FS}{if (NR!=1) {  if ($16 =="[country_code]")  { print}    } else {print}}' planet-latest.tsv > countryExtract.tsv
```
where country_code is the ISO-3166 2-letter country code.



### Get Started

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

This will call the script `src/run.sh` in the docker container, which will execute following steps:
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
