#!/bin/bash
set -o errexit
set -o pipefail
set -o nounset

function create_template_postgis() {
    PGUSER="$POSTGRES_USER" psql --dbname="$POSTGRES_DB" <<-'EOSQL'
		CREATE DATABASE template_postgis;
		UPDATE pg_database SET datistemplate = TRUE WHERE datname = 'template_postgis';
	EOSQL
}

function execute_sql_into_template() {
    local sql_file="$1"
    PGUSER="$POSTGRES_USER" psql --dbname="template_postgis" -f "$sql_file"
}

function create_postgis_extensions() {
    cd "/usr/share/postgresql/$PG_MAJOR/contrib/postgis-$POSTGIS_MAJOR"
    local db
    for db in template_postgis "$POSTGRES_DB"; do
        echo "Loading PostGIS into $db"
        PGUSER="$POSTGRES_USER" psql --dbname="$db" <<-'EOSQL'
			CREATE EXTENSION postgis;
		EOSQL
    done
    }

function main() {
    create_template_postgis
    create_postgis_extensions
}

main
