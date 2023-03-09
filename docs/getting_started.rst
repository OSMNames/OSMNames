Getting Started
===============

System requirements
-------------------
With the following set of commands one can easily setup OSMNames in a matter of
minutes. Prerequisites are a working installation of Docker
https://www.docker.com/ along with Docker Compose.

.. Note::
  In order to increase the speed of the processing, an SSD disk is recommended.
  It is also recommended to tweak the database settings to match the
  specficiations of your system.


Run OSMNames
--------------

To run OSMNames, follow these steps:

1.	Checkout source from GitHub

	  .. code-block:: bash

	  	git clone https://github.com/OSMNames/OSMNames.git

2.	Specify the URL to the PBF file in the `.env` file

	  .. code-block:: bash

		PBF_FILE_URL=https://download.geofabrik.de/europe/switzerland-latest.osm.pbf


	Alternatively place a custom PBF file in the `data/import` directory and define it in the `.env` file

	  .. code-block:: bash

		PBF_FILE=Zuerich.osm.pbf

	If `PBF_FILE` is defined `PBF_FILE_URL` will be ignored.

3.	Now run OSMNames
	  .. code-block:: bash

		docker-compose run --rm osmnames

  This command will:

  1. Initialize the database inside a docker container
  2. Download and import a wikipedia dump
  3. Download and process the specified PBF file
  4. Export the OSMNames data

  The export files for example, `switzerland_geonames.tsv.gz` and
  `switzerland_housenumbers.tsv.gz` can be found in the export directory
  `data/export`.

  A more detailed and technical overview can be found in `the documentation
  about the Implementation <implementation/index.html>`_.

  .. Note::
    The execution time is highly dependent from the size of the PBF file and
    the available hardware. More details about the performance can be found in
    `the corresponding documentation <others.html#performance>`_.


Extracting countries
--------------------
The TSV file from the planet export includes more than 21'000'000 entries. The
current data export can be downloaded at https://osmnames.org. If one is only
interested in a specific country, download the file and extract the information
with the following command:

  .. code-block:: bash

  	awk -F $'\t' 'BEGIN {OFS = FS}{if (NR!=1) {if ($16 =="[country_code]")  {print}} else {print}}' planet-latest.tsv > countryExtract.tsv

where [country_code] needs to be replaced with the ISO-3166 2-letter country code.
