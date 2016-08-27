
Installation
============

.. Note::
  In order to increase the speed of the processing, an SSD disk is recommended. It is also recommended to tweak the database settings to match the specficiations of your system.

  A 100 GB disk should be sufficient to run the data.

System requirements
-------------------
With the following set of commands one can easily setup OSMNames in a matter of minutes. Prerequisites are a working installation of Docker https://www.docker.com/ along with Docker compose.


Involved steps
--------------

Installations assume you use UTF8. You can set the locale by doing this:


1.	Checkout source from GitHub

	  .. code-block:: bash

	  	git clone https://github.com/geometalab/OSMNames.git

2.	Either download specific PBF manually or the planet dump with the following Docker task
	
	  .. code-block:: bash
		
		docker-compose run download-pbf
		wget --directory-prefix=./data http://download.geofabrik.de/europe/switzerland-latest.osm.pbf

3.	Setup the database
	  .. code-block:: bash
	
		docker-compose up -d postgres

4.	Import wikipedia data
	  .. code-block:: bash
	
		docker-compose run import-wikipedia

5.	Create the schema
	  .. code-block:: bash
	
		docker-compose run schema

6.	Import the OSM data from the PBF file
	  .. code-block:: bash
	
		docker-compose run import-osm

7.	Export the data to a TSV file
	  .. code-block:: bash
	
		docker-compose run export-osmnames

That’s it. The export file can be found in the data folder.

Extracting countries
--------------------
The TSV file from the planet export includes 21'055'840 entries. The current data export can be downloaded at https://osmnames.org.
If one is only interested in a specific country, he or she can download the file and easily extract the information with the following command:

  .. code-block:: bash

  	awk -F $'\t' 'BEGIN {OFS = FS}{if (NR!=1) {  if ($16 =="[country_code]")  { print}    } else {print}}' planet-latest.tsv > countryExtract.tsv

where [country_code] needs to be replaced with the ISO-3166 2-letter country code.
