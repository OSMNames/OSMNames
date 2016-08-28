OSMNames Introduction
====================

OSMNames is an open source tool that allows creating geographical gazetter data
out of OpenStreetMap OSM files.

There is a need for a data set consisting of street names of the world. Such gazetteer data however is either not available for every country (openaddresses.io) or is not in a suitable format. Furthermore, if such data is found, it is often not for free. A global data set can be downloaded at https://osmnames.org.

A current implementation on how the data looks like in a geocoder can be seen at https://osmnames.klokantech.com

.. image:: static/map_preview.png
   :alt: OSMNames Geocoder
   :align: center
   :scale: 75%

What can I do with OSMNames?
----------------------------

With OSMNames, you can create your own geocoder data set based on OpenStreetMap. It currently includes all addresses available without house numbers and zip codes. For each feature a hierarchy as well as an Wikipedia-based importance is calculated.
