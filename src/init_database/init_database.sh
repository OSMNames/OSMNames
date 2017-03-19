#!/bin/bash
set -o errexit
set -o pipefail
set -o nounset

function create_database() {
    echo "Creating database $DB_NAME with owner $DB_USER"
    psql --user="postgres" --dbname="postgres" <<-EOSQL
			CREATE USER $DB_USER WITH PASSWORD '$DB_PASSWORD';
			CREATE DATABASE $DB_NAME WITH TEMPLATE template_postgis OWNER $DB_USER;
		EOSQL
}

function create_hstore_extension() {
    psql --user="postgres" --dbname="$DB_NAME" <<-'EOSQL'
			CREATE EXTENSION IF NOT EXISTS hstore;
		EOSQL
}

function main() {
  if psql -c "select exists (select 1 from pg_type where typname = 'rankPartitionCode');" > /dev/null 2>&1; then
      echo "Skipping database initializations, since it seems already initialized"
      return
    fi

    create_database
    create_hstore_extension

    echo "create schema"
    exec_psql_file "functions.sql"
}

main
