Import OSM
==========

.. image:: /static/bpmns/import_osm.svg
   :alt: Import OSM
   :align: center
   :scale: 100%


The PBF file can be set with the environment variable `PBF_FILE_URL` or
`PBF_FILE`. When defining the URL, the file is download, if not already present
in the import directory. When the file is defined directly, the download is
skipped.

Before importing the PBF file with Imposm, the database is sanitized by
dropping all previously imported tables.

To import the PBF file `Imposm3 <https://imposm.org/docs/imposm3/latest/>`_ is
used, which is an importer for OpenStreetMap data. The corresponding mapping
can be found `here
<https://github.com/OSMNames/OSMNames/blob/master/data/import/mapping.yml>`_.
After the import, the following tables will be created:

* osm_linestring
* osm_polygon
* osm_point
* osm_housenumber
* osm_relation
* osm_relation_member

More details about the columns of the tables can be found in the `mapping of
Impsom3
<https://github.com/OSMNames/OSMNames/blob/master/data/import/mapping.yml>`_.
Additionally, will the tables be extended with custom columns `when preparing
the data <prepare_data.html#configure-for-preparation>`_.


.. _import-helper-tables:

Import Helper Tables
********************

Besides the OpenStreetMap data, are the following tables imported:

================  =====================================================================
Table             Description
================  =====================================================================
country_osm_grid  Contains the country code and geometries for all countries.
country_name      Contains the country code and country names of all countries.
================  =====================================================================

The tables are later used to enrich the imported data. Both are provided by
`Nominatim <https://github.com/openstreetmap/Nominatim>`_.
