Prepare Data
============

The preparation of the imported OpenStreetMap data for the export is the heart
of OSMNames. Missing names are completed, a hierarchy is created, unusable
entries are removed and more. In this document are all involved steps explained
in detail. The following diagram shows the full process of preparing the data:

.. image:: /static/bpmns/prepare_data.png
   :alt: Prepare Data
   :align: center
   :scale: 100%


configure for preparation
*************************
This step configures the database for the other steps. This involves:

* Dropping unused indexes for better performance
* Add custom columns, necessary for the preparation, to tables imported in
  `prepare_data`. The added columns can be found `here
  <https://github.com/OSMNames/OSMNames/blob/master/osmnames/prepare_data/create_custom_columns.sql>`_.
* Set tables to unlogged for better performance



set names
*********

The following approaches are used to complete the name and alternative_names
attribute on polygons, linestrings and points.

set names from tags
-------------------

All tags of polygons, linestrings and points are imported. On some elements is
the name not set with the key `name:en` but with a different key, e.g.
`name:fr`.  The value of the name attribute is tried to set with following
approaches, whereas the order matches the priority:

1. Set the name to the imported `name:en` if present.
2. Set the name to the first present value of these keys, whereas the order matches the priority:
    1. `name`
    2. `name:fr`
    3. `name:de`
    4. `name:es`
    5. `name:ru`
    6. `name:zh`
3. If still no name is found, take the first alternative name.

Additionally is the attribute `alternative_names` set with all available names,
except the value of the name attribute. The value of `alternative_names` is a
comma separated string.

.. note:: All available names for the alternative names are determined by the
  keys of the tags. Keys starting with `name:` and others are considered. Details
  about the relevant keys can be found in `the corresponding query
  <https://github.com/OSMNames/OSMNames/blob/master/osmnames/prepare_data/set_names/set_names_from_tags.sql>`_.

.. note:: Tabs in the name or alternative_names are replaced with spaces, since
  the final export format is TSV.

Example
~~~~~~~

A node was imported with following attributes:

================  =====================================================================
Attribute         Value
================  =====================================================================
name              NULL
all_tags          { "name:de": "Matterhorn", "name:fr": "Cervin", "name:it": "Cervino" }
================  =====================================================================

After running set_names_from_tags, the following values are set:

=================  =====================  ==============================================================================
Attribute          Value                  Explanation
=================  =====================  ==============================================================================
name               Cervin                 The French name from all_tags because the name and `name:en`
                                          attribute was empty and French has a higher priority then German
alternative_names  Matterhorn, Cervino    All remaining names from all_tags, except the French, since it was set as name
=================  =====================  ==============================================================================



set linestring names from relations
-----------------------------------
Sometimes is the name not set on a linestring directly, but on the relation,
where the linestring is a member. If so, the name is set to the name of the
relation.

Implemented with `Issue #106 <https://github.com/OSMNames/OSMNames/issues/106>`_.





delete unusable entries
***********************
Elements are unusable and deleted if:

* Name attribute of polygons, points or linestrings is still empty.
* Geometry of polygons is empty.





set place ranks
***********************
The place rank indicates how important a element is (lower means more
important). A continent for example has a place_rank of 2, which is the lowest
place_rank possible. The place_rank is either the double of the admin_level, if
the admin_level is set, or a value depending on the type of the element. The
mapping can be found `here
<https://github.com/OSMNames/OSMNames/blob/master/osmnames/prepare_data/set_place_ranks.sql>`_.





set country codes
***********************
To determine the country of a element, the country_code must be present on each
polygon. It is only necessary for polygons since the country code of all other
elements can be determined based on the hierarchically associated polygon.

If present the imported country_code is taken. Otherwise is the country code
set based on the `country_osm_grid <import_osm.html#import-helper-tables>`_.





determine linked places
***********************
In order to determine linked places (points linked with polygons) additional
tags about the relations are imported. Specifically, the role values
admin_centre and label are of interest.

This information is later on used in the export mainly to rule out point
features linked to their polygon features as well as determining city types
instead of administrative types.

For example the relation `Kreuzberg
<http://www.openstreetmap.org/relation/55765>`_ is linked to the member node
`Kreuzberg <http://www.openstreetmap.org/node/262328235>`_ with the role
`label`. Since they are linked, only the polygon will be exported.





create hierarchy
****************
The hierarchy of the elements is created based on their geometries. The process
is as simple as this:

1. Set the parent id of each element within a polygon, with the place rank 22,
   to the id of the polygon. Polygons with the place rank 22 have the admin
   level 11 or the type `neighbourhood` or `residential`.

.. note:: The parent id of a polygon is only set if the place rank is higher than the
   place rank of the parent. This prevents a meaningless hierarchy.

2. When all polygons with the place rank 22 are processed, the same step is
   done with all polygons with the place rank 21, 20, 19 and so forth.

3. It ends with the place rank 2, which corresponds to polygons of the type
   `continent`.

.. note:: If a element is contained in a polygon, is determined with the PostGIS
  function `st_contains <http://postgis.net/docs/manual-1.4/ST_Contains.html>`_.
  Since it only returns true if a geometry is fully contained in another
  geometry, the child elements are determined only with the center of a geometry
  and not the full geometry. The centers of geometries are set `here
  <https://github.com/OSMNames/OSMNames/blob/master/osmnames/prepare_data/create_hierarchy/set_geometry_centers.sql>`_.

.. note:: Polygons of the type `water`, `desert`, `bay` and `reservoir` are
  ignored, since it makes no sense to assign them as parents of other elements.




merge corresponding linestrings
*******************************
Linestrings are merged to one linestring if all of these conditions are met:

* They have the same name
* They have the same polygon as parent
* They are at least 1000 meters near each other

When merging the linestring a new table `osm_merged_linestring` is created,
which contains, besides the shared attributes of the sub-linestrings, following
attributes:

================  =====================================================================
Attribute         Description
================  =====================================================================
osm_id            Smallest id of the sub-linestring ids.
member_ids        The ids of the sub-linestrings.
type              Types of the sub-linestrings, comma separated.
geometry          Combination of the sub-linestring geometries.
================  =====================================================================

.. note:: The geometry of the merged linestring is sligthly simplified with the
  PostGIS function `st_simplify <https://postgis.net/docs/ST_Simplify.html>`_,
  see `Issue #90 <https://github.com/OSMNames/OSMNames/issues/90>`_

After creating the table `osm_merged_linestring`, the attribute `merged_into`
of the original linestrings in the table `osm_linestring` are updated to the
`osm_id` of the linestring they have been merged into.

Examples
--------
For example the linestrings with the OSM IDs `26085954
<http://www.openstreetmap.org/way/26085954>`_, `289620118
<http://www.openstreetmap.org/way/289620118>`_, `289620119
<http://www.openstreetmap.org/way/289620119>`_ are merged to one linestring.

Other examples can be found in the issues `#74
<https://github.com/OSMNames/OSMNames/issues/74>`_ and `#85
<https://github.com/OSMNames/OSMNames/issues/85>`_.





prepare housenumbers
********************
The goal of preparing the house numbers is, to connect each geometry, which has
an house number as attribute, to a corresponding street or place. All
geometries with an house number are imported into the `osm_housenumber` table.
Some of them have already the `street` attribute set, with the name of a
street.  Others do only have the `housenumber` attribute and nothing else set.
For these house numbers multiple approaches are applied to complete the missing
`street` attributes. The steps are shown by the following diagram:


.. image:: /static/bpmns/prepare_housenumbers.png
   :alt: Prepare House Numbers
   :align: center
   :scale: 100%


.. note:: The individual steps are sorted according to their costs. It is for
  example fast to determine the missing street attribute from a relation, if one
  exists. But it is slow and costly to find the nearest street depending on the
  geometry.


set street attributes by street relation members
------------------------------------------------
If a house number is part of a relation, where another member has the role
`street` or `associatedStreet`, set the `street_id` and the `street` to the
`osm_id` and `name` of this member.


set street names by relation attributes
---------------------------------------
If a house number is part of a relation with the type `street` or
`associatedStreet`, set the `street` to the `street` or `name` attribute of
this relation.


normalize street names
----------------------
To match house numbers with streets by the street name, the attributes
`normalized_street` and `normalized_name` of house numbers and linestrings are
set to a normalized version of the street and name. The name is normalized by:

* removing all white spaces and dashes
* lower casing the name
* removing accents

Some examples for normalized names and streets:

========================  ========================
Name / Street             Normalized Name / Street
========================  ========================
Bietinger Weg             bietingerweg
Cité Préville             citepreville
Chemin du Pra-de-Villars  chemindupradevillars
Rue de'Gare               ruedegare
========================  ========================


set street ids by street name
-----------------------------
It is tried to set the `street_id` of the house numbers to the `osm_id` of a
linestring, which has the same `parent_id` and a matching name. These
approaches are executed in the given order:

1. Find a linestring with **the same parent_id** and the **exactly** same `name` as
   the `street` of the house number.

2. Find a **within 1000 meters** and the **exactly** same `name` as the
   `street` of the house number.

3. Find a linestring with **the same parent_id** and the **most similar** `name`.
   This approach makes use of the `PostgreSQL module pg_trgm
   <https://www.postgresql.org/docs/9.6/static/pgtrgm.html>`_.

4. Find a **within 1000 meters** and the **most similar** `name`.  This
   approach makes use of the `PostgreSQL module pg_trgm
   <https://www.postgresql.org/docs/9.6/static/pgtrgm.html>`_.

.. note:: The approaches are executed in this order because the more accurate
  and best performing approaches are executed first. If still no street was
  found, the restrictions are softened.

Here some examples for the matching street names. Note that in the queries the
matching is done with the normalized name.

========================  ========================
House number street       Linestring name
========================  ========================
Haldenweg                 Haldenweg
Bochslenrasse             Bochslenstrasse
Cité Préville 19          Cité Préville
========================  ========================


set street attributes by nearest street
---------------------------------------
Still not all house numbers will have a street assigned at this point. As the
last approach will the **nearest** street be assigned to the house number. Note
that this is **very slow, expensive and inaccurate** and therefore is only
executed if no street was found with the previous approaches.
