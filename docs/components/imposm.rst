Imposm3
=======

`Imposm3 <https://imposm.org/docs/imposm3/latest/index.html>`_ by Omniscale is a data importer for OpenStreetMap data. It reads PBF files and writes the data into the PostgreSQL database.
In OSMNames it is used in favor of osm2pgsql mainly because of its superior speed results. It makes heavy use of parallel processing favoring multicore systems. Explicit tag filters are set in order to have only the relevant data imported. Due to the fact that imposm3 cannot import multiple geometry types into a single table, separate tables are created for points, linestrings as well as polygons.