# OSM Names

Database of geographic place names from OpenStreetMap for full text search downloadable for free. Website: http://osmnames.org

## Target of the project

- Downloadable gazeteer data a la GeoNames.org: http://download.geonames.org/export/dump/ but each record has bounding box and an importance rank known from Nominatim
- Data are derived primarily from OpenStreetMap
- The data format is simple to use tab-delimited text in utf8 encoding (as geonames.org). First line has column names.
- Different type of records are stored in different files (download and index just what you need, sometimes you don't need POIs or addresses with house numbers)
- Tight to the OSM2VectorTiles generator (class/type from vector tiles, exporting names available in vector tiles, regular diff updates possible)
- Possible to generate from a country specific extract of Open Street Map (together with vector tiles)

## Why to make this

- Direct indexing via fulltext search engines (SphinxSearch, ElasticSearch, etc.)
- Simple process to get a **basic** search in place names on a map within minutes
- Downloading the basic gazeteer data from OSM in usable format is problematic now (a need to process large OSM Planet files)

## Sample search server

- Powered by super fast open-source fulltext Sphinxsearch - inspired by Swiss GeoAdmin search service
- JSON/JSONP API similar to Nominatim: http://nominatim.klokantech.com/?q=paris&format=jsonv2&addressdetails=1
- Ready to use via Docker in minutes
- https://github.com/klokantech/osmnames-sphinxsearch

## Data format of OSMNames

```
*osm_id - MUST BE UNIQUE "DOCUMENT ID" accross complete database

display_name - exactly as in Nominatim (may be improved later)

*name (=utf-8)
name_en
name_de
name_es
name_fr
name_ru
name_zh

*class
*type

*north (=boundingbox)
*south
*east
*west

*lat
*lon

scalerank - we have it
place_rank - nominatim has it

importance - exactly as in nominatim calculated

country (=country code, ISO-3166 2-letter country code)

street=<housenumber> <streetname>
city=<city>
county=<county>
state=<state>
country=<country>

(= a la nominatim http://wiki.openstreetmap.org/wiki/Nominatim)

? timestamp - osm modification?
```

REMARKs: 
* Fields like housenumber and postalcode don't belong to this dataset. There's a dataset "OSM Adresses" for that.


### Get Started

You need a complete OSM PBF data dump either from a [country extract](http://download.geofabrik.de/index.html) or of the [entire world](http://planet.osm.org/).
Download the data and put it into the `data` directory.

```bash
wget --directory-prefix=./data http://download.geofabrik.de/europe/switzerland-latest.osm.pbf
```

Now we need to set up the database and import the data using the `import-osm` Docker container.

```bash
# This will automatically initialize the database
docker-compose up -d postgres

# Import additional wikipedia data to the ./data folder
docker-compose run import-wikipedia
```

# Import the OSM data dump from the ./data folder
docker-compose run import-osm
```

Create the database schema.

```bash
docker-compose run schema
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
| import-wikipedia  | Imports wikipedia data for more accurate importance calculation
| import-osm        | Imposm3 based import tool with custom mapping to import selective OSM into the database and reconstruct it as GIS geometries, handles indexing and hierarchy reconstruction
| export-osmnames   | Export names and their bounding boxes to TSV datasets
| schema            | Contains views, tables, functions for the schema
