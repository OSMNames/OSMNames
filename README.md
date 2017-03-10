# OSM Names

Database of geographic place names from OpenStreetMap for full text search downloadable for free. Website: http://osmnames.org
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

```
name 				the name of the feature (default language is en, others available(de,es,fr,ru,zh))
alternative_names	all other available and distinct names separated by commas
osm_type			the osm type of this feature (node, way, relation)
osm_id
class
type
lon
lat
place_rank			rank from 1-30 ascending depending on the type and class
importance			importance [0.0-1.0] depending on wikipedia if available otherwise just the ranking
street
city
county
state
country
country_code		ISO-3166 2-letter country code
display_name		the display name representing the hierarchy
west				bbox
south				bbox
east				bbox
north				bbox
wikidata			the wikidata associated with this feature
wikipedia 			the wikipedia URL associated with this feature

```

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

You need a complete OSM PBF data dump either from a [country extract](http://download.geofabrik.de/index.html) or of the [entire world](http://planet.osm.org/).
Download the data and put it into the `data` directory.

```bash
wget --directory-prefix=./data http://download.geofabrik.de/europe/switzerland-latest.osm.pbf
```

Alternatively there is a docker-compose, just edit FILE_URL in download-pbf.sh accordingly

```bash
docker-compose run download-pbf
```

Now we need to set up the database and import the data using the `import-osm` Docker container.

```bash
# This will automatically initialize the database
docker-compose up -d postgres
```

```bash
# Import additional wikipedia data to the ./data folder
docker-compose run import-wikipedia
```

Create the database schema

```bash
docker-compose run schema
```

Import the pbf file from the data folder

```bash
# Import the OSM data dump from the ./data folder
docker-compose run import-osm
```


We can now export the ranked geonames and their geometries.

```bash
docker-compose run export-osmnames
```

### Components

The different components that attach to the `postgres` container are all located in the `src` directory.

| Component         | Description
|-------------------|--------------------------------------------------------------
| postgres          | PostGIS data store for OSM data and to perform noise analysis
| download-pbf      | automatically downloads the pbf file
| import-wikipedia  | Imports wikipedia data for more accurate importance calculation
| import-osm        | Imposm3 based import tool with custom mapping to import selective OSM into the database and reconstruct it as GIS geometries, handles indexing and hierarchy reconstruction
| export-osmnames   | Export names and their bounding boxes to TSV datasets
| schema            | Contains views, tables, functions for the schema
