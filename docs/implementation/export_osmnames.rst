Export OSMNames
===============

When exporting OSMNames the output files get created. This documents describes
the implementation of the export. `Details about the output format can be found
in the introduction <../introduction.html#output-format>`_.

create functions
****************
This step creates the SQL functions later used for the export.

Besides the following descriptions of the functions are `the unit tests of
Python
<https://github.com/OSMNames/OSMNames/tree/master/tests/export_osmnames>`_ a
good entry point to understand how the functions work.

determine_class
---------------
Returns a class for a given type. For example, the type `city` leads to the class `place`.

The full mapping can be found in `the code
<https://github.com/OSMNames/OSMNames/blob/master/osmnames/export_osmnames/functions.sql>`_.


get_parent_info
---------------
This function makes use of the hierarchy and the place rank to return the
following information for an element:

* city
* county
* state
* country_code
* display name

Whereas the display name is a concatenation of the name of the element and all
other information.

.. note:: More information about the impelementation of the function can
  be found in the `PR #82 <https://github.com/OSMNames/OSMNames/pull/82>`_

**Example**

These elements exists:

=========== === ======================== =========
Type        ID  Name                     Parent ID
=========== === ======================== =========
Linestring  1   Oberseestrasse           2
Polygon     2   Rapperswil-Jona          3
Polygon     3   Wahlkreis See-Gaster     4
Polygon     4   Sankt Gallen             5
Polygon     5   Schweiz                  \-
=========== === ======================== =========

When calling the function `get_parent_info` with the parent id and the name of
linestring `Oberseestrasse` following information will be returned:

============== ===========================
Attribute      Value
============== ===========================
city           Rapperswil-Jona
county         Wahlkreis See-Gaster
state          Sankt Gallen
country_code   ch
display name   Oberseestrasse, Rapperswil-Jona, Wahlkreis See-Gaster, Sankt Gallen, Switzerland
============== ===========================


.. note:: The decision which polygon is the city, county or state is based on
  the corresponding place rank.



get_country_name
----------------
Returns the name of a country for a given country code. The name will be
returned in the first language present, following the precedence: [English ->
native name -> French -> German -> Spanish -> Russian -> Chinese].

The names are read from the helper table `country_name` (see
:ref:`import-helper-tables`).


get_importance
--------------
This function returns an importance for an element by its URL to a wikipedia
article if present or its place rank.

If a feature has a wikipedia URL a matching entry in the wikipedia helper table
is taken for calculating the importance with the following formula:

.. code-block:: bash

  importance = log (totalcount) / log( max(totalcount))

where totalcount is the number of references to the article from other
wikipedia articles. In case there is no wikipedia information or no match was
found, the following formula is applied:

.. code-block:: bash

  importance = 0.75 - (place_rank/40)

Since every feature has a rank, it is ensured that every feature also has an
importance.



get_country_language_code
-------------------------
Returns the default language for a country. The value is read from the helper
table `country_name` (see :ref:`import-helper-tables`).



get_housenumbers
----------------
Returns a comma separated string of all house numbers, associated to the given
`osm_id`.



get_bounding_box
----------------
This functions takes a geometry, a country code and an admin_level as attribute
and determines a bounding box. It is only used for polygons to handle these
special cases:

* Some countries do have colonies where are big bounding box is returned. Since
  this is inconvenient from a user perspective, a smaller bounding box, only
  covering the main country is returned. See `Issue #57
  <https://github.com/OSMNames/OSMNames/issues/57>`_ for more details.

* When a polygons intersects the antimeridian, a unintuitive bounding box is
  returned. In this case the bounding box is shifted manually. See `Issue #94
  <https://github.com/OSMNames/OSMNames/issues/94>`_ for more details.


create views
************
This function creates the views, which are later used to export the geonames
and house numbers. The columns of the views equals `the output format of
OSMNames <../introduction.html#output-format>`_.


export geonames
***************
This function exports all rows of the polygon, linestring and point view to the
file `<import-file-name>_geonames.tsv`. This by making use of the `PostgreSQL
function COPY <https://www.postgresql.org/docs/current/static/sql-copy.html>`_.


export housenumbers
*******************
This function exports all rows of house number view to the file
`<import-file-name>_housenumbers.tsv`. This by making use of the `PostgreSQL
function COPY <https://www.postgresql.org/docs/current/static/sql-copy.html>`_.

.. note:: House numbers unable to associated to a street or place when
  preparing the data, are not exported.

gzip tsv files
**************
This function finally uses `gzip <http://www.gzip.org/>`_ to compress the `tsv`
files created before.
