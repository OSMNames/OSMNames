#!/bin/bash
set -o errexit
set -o pipefail
set -o nounset

function create_template_postgis() {
    psql --user="postgres" --dbname="postgres" <<-'EOSQL'
		CREATE DATABASE template_postgis;
		UPDATE pg_database SET datistemplate = TRUE WHERE datname = 'template_postgis';
	EOSQL
}

function create_postgis_extensions() {
    psql --user="postgres" --dbname="$DB_NAME" <<-'EOSQL'
			CREATE EXTENSION IF NOT EXISTS postgis;
		EOSQL
}

function create_database() {
    echo "Creating database $DB_NAME with owner $DB_USER"
    psql --user="postgres" --dbname="postgres" <<-EOSQL
		CREATE USER $DB_USER WITH PASSWORD '$DB_PASSWORD';
		CREATE DATABASE $DB_NAME WITH TEMPLATE template_postgis OWNER $DB_USER;
	EOSQL
}

function main() {
    create_database
    create_template_postgis
    create_postgis_extensions

    echo "create schema"
    exec_psql_file "functions.sql"
}

main
