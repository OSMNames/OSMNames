==============
Implementation
==============

This document describes the implementational aspects of OSMNames.

OSMNames is written in Python. Whereas the main entry point is the file `run.py
<https://github.com/philippks/OSMNames/blob/master/run.py>`_. The script calls
the necessary tasks in the correct order. The following diagram shows the full
process of OSMNames:

.. image:: /static/bpmns/run.svg
   :alt: OSMNames Process
   :align: center
   :scale: 100%

Details about the tasks can be found in the particular documents:

.. toctree::
   :maxdepth: 2

   initialize_database
   import_wikipedia
   import_osm
   prepare_data
   export_osmnames
