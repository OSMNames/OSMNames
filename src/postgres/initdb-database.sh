#!/bin/bash
set -o errexit
set -o pipefail
set -o nounset

readonly DB_NAME=${DB_NAME:-noise}
readonly DB_USER=${DB_USER:-noise}
readonly DB_PASSWORD=${DB_PASSWORD:-noise}

function create_db() {
    echo "Creating database $DB_NAME with owner $DB_USER"
    PGUSER="$POSTGRES_USER" psql --dbname="$POSTGRES_DB" <<-EOSQL
		CREATE USER $DB_USER WITH PASSWORD '$DB_PASSWORD';
		CREATE DATABASE $DB_NAME WITH TEMPLATE template_postgis OWNER $DB_USER;
	EOSQL
}

create_db
