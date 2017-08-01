Components
==========
OSMNames consists of the following components:

Docker
******
OSMNames is built with `Docker <https://www.docker.com/>`_ and is therefore
shipped in containers. This allows to have an extra layer of abstraction and
avoids overhead of a real virtual machine. Specifically, it is built with
`docker-compose <https://docs.docker.com/compose/>`__ thus allowing to define a
multi-container architecture defined in a single file.


Imposm3
*******
`Imposm3 <https://imposm.org/docs/imposm3/latest/index.html>`_ by Omniscale is
a data importer for OpenStreetMap data. It reads PBF files and writes the data
into the PostgreSQL database.  In OSMNames it is used in favor of osm2pgsql
mainly because of its superior speed results. It makes heavy use of parallel
processing favoring multicore systems. Explicit tag filters are set in order to
have only the relevant data imported.


PostgreSQL
**********

`PostgreSQL <http://postgresql.org>`_ is the open source database powering
OMSNames.

OSMNames uses PostgreSQL for the following tasks:

* Storing OSM data read from PBF file.

* OSM data processing

* data export to TSV file

At this moment OSMNames runs PostgreSQL 9.6.x version.

PostGIS
-------

`PostGIS <http://postgis.net>`_ is the extension which adds spatial
capabilities to PostgreSQL. It allows working with geospatial types or running
geospatial functions in PostgreSQL.

At this moment OSMNames runs PostGIS 2.3 version.
