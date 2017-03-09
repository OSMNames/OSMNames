FROM mdillon/postgis:9.5
MAINTAINER Lukas Martinelli <me@lukasmartinelli.ch>

# copy new initdb file which enables the hstore extension and Mapbox vt-util functions
RUN rm -f /docker-entrypoint-initdb.d/postgis.sh
COPY ./initdb-postgis.sh /docker-entrypoint-initdb.d/10_postgis.sh
COPY ./initdb-database.sh /docker-entrypoint-initdb.d/20_database.sh
