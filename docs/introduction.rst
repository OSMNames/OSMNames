Introduction
============

OSMNames is an open source tool that allows creating geographical gazetteer data
out of OpenStreetMap OSM files.

There is a need for a data set consisting of street names of the world. Such
gazetteer data, however, is either not available for every country
(openaddresses.io) or is not in a suitable format. Furthermore, if such data
exists, it is often not for free. A global data set can be downloaded at
https://osmnames.org.

A current implementation on how the data looks like in a geocoder is a
available at https://osmnames.org

.. image:: static/map_preview.png
   :alt: OSMNames Geocoder
   :align: center
   :scale: 75%



What can I do with OSMNames?
----------------------------

With OSMNames, you can create your own geocoder data set based on
OpenStreetMap. It currently includes all addresses available. For each feature,
the hierarchy, as well as a Wikipedia-based importance, is calculated.



Where to Start?
---------------

To download the newest set of data go to https://osmnames.org.

To process OpenStreetMap data yourself, check out the `Getting Started
document <getting_started.html>`_.

If you want to have a look at the Source Code or contribute to the project,
check out the `Development <development.html>`_ documentation. The source code
is available in our `GitHub Repository
<https://github.com/OSMNames/OSMNames/issues>`_.


Output Format
-------------

The exported file `geonames.tsv` contains the following columns:

================== ======================================================================================================
Column name        Description
================== ======================================================================================================
name               The name of the feature (default language is en, others available are de, es, fr, ru, zh)
alternative_names  All other available and distinct names separated by commas
osm_type           The OSM type of the feature (node, way, relation)
osm_id             The unique osm_id as identifier for the house numbers in the second file `housenumbers.tsv`
class              The class of the feature e.g. boundary
type               The type of the feature e.g. administrative
lon                The decimal degrees (WGS84) longitude of the centroid of the feature
lat                The decimal degrees (WGS84) latitude of the centroid of the feature
place_rank         Rank from 1-30 ascending, 1 being the highest. Calculated with the type and class of the feature.
importance         Importance of the feature, ranging [0.0-1.0], 1.0 being the most important.
street             The name of the street if the feature is some kind of street
city               The name of the city of the feature, if it has one
county             The name of the county of the feature, if it has one
state              The name of the state of the feature, it it has one
country            The name of the country of the feature
country_code       The ISO-3166 2-letter country code of the feature
display_name       The display name of the feature representing the hierarchy, if available in English
west               The western decimal degrees (WGS84) longitude of the bounding box of the feature
south              The southern decimal degrees (WGS84) latitude of the bounding box of the feature
east               The eastern decimal degrees (WGS84) longitude of the bounding box of the feature
north              The northern decimal degrees (WGS84) latitude of the bounding box of the feature
wikidata           The wikidata associated with the feature
wikipedia          The wikipedia URL associated with the feature
housenumbers       All house numbers, comma separated, associated to this element. Coordinates of the house numbers are part of the second output file `housenumbers.tsv`
================== ======================================================================================================

.. note:: All coordinates are rounded to seven digits after the decimal point.

.. note:: The `housenumbers` column is a redundant information of all house
  numbers contained in the file `housenumbers.tsv`. The redundancy is accepted
  due to advantages for the full-text search of geocoders.

The second file `housenumber.tsv` contains the following columns:

================== ======================================================================================================
Column name        Description
================== ======================================================================================================
osm_id             The unique osm_id for debug purposes
street_id          The osm_id of the element, the house number is associated to
street             The name of the street it is associated to for debug purposes
housenumber        The actual house number
lon                The decimal degrees (WGS84) longitude of the centroid of the house number
lat                The decimal degrees (WGS84) latitude of the centroid of the house number
================== ======================================================================================================
