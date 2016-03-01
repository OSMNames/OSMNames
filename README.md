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

## Data format

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
postalcode=<postalcode>

(= a la nominatim http://wiki.openstreetmap.org/wiki/Nominatim)

? timestamp - osm modification?
```
