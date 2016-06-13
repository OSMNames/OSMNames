#!/bin/bash
set -o errexit
set -o pipefail
set -o nounset

readonly IMPORT_DATA_DIR=${IMPORT_DATA_DIR:-/data/import}
readonly DB_HOST=$DB_PORT_5432_TCP_ADDR
readonly PG_CONNECT="postgis://$DB_USER:$DB_PASSWORD@$DB_HOST/$DB_NAME"

readonly DB_PORT=$DB_PORT_5432_TCP_PORT


function exec_psql_file() {
    local file_name="$1"
    PG_PASSWORD="$DB_PASSWORD" psql \
        -v ON_ERROR_STOP=1 \
        --host="$DB_HOST" \
        --port="$DB_PORT" \
        --dbname="$DB_NAME" \
        --username="$2" \
        -f "$file_name"
}

function load_wiki_dump() {
    echo "$(date +"%T"): try to load wikipedia dump.."
    local file_name="$IMPORT_DATA_DIR/wikipedia_article.sql.bin"
    exec_psql_file "wiki_privileges.sql" "postgres"
    if [ ! -f "$file_name" ]; then
        wget --output-document=$file_name http://www.nominatim.org/data/wikipedia_article.sql.bin
    fi
    pg_restore -h $DB_HOST -d $DB_NAME -p $DB_PORT -U brian $file_name
    echo "$(date +"%T"): wikipedia loading complete.."
    exec_psql_file "wiki_transfer_ownership.sql" "postgres"
}

function main() {
        load_wiki_dump
}

main
