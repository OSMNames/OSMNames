#!/bin/bash
set -o errexit
set -o pipefail
set -o nounset

readonly IMPORT_DATA_DIR=${IMPORT_DATA_DIR:-/data/import}
readonly IMPOSM_CACHE_DIR=${IMPOSM_CACHE_DIR:-/data/cache}
readonly MAPPING_JSON=${MAPPING_JSON:-/usr/src/app/mapping.json}

readonly DB_HOST=$DB_PORT_5432_TCP_ADDR
readonly PG_CONNECT="postgis://$DB_USER:$DB_PASSWORD@$DB_HOST/$DB_NAME"

readonly DB_PORT=$DB_PORT_5432_TCP_PORT

function import_pbf() {
    
    local pbf_file="$1"
    imposm3 import \
        -connection "$PG_CONNECT" \
        -mapping "$MAPPING_YAML" \
        -overwritecache \
        -cachedir "$IMPOSM_CACHE_DIR" \
        -read "$pbf_file" \
        -dbschema-import="${DB_SCHEMA}" \
        -write
}

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

function indexing_phase() {
    echo "$(date +"%T"): start indexing.."
    # exec_psql_file "indexing.sql" "$DB_USER"
    echo "$(date +"%T"): indexing complete.."
}

function load_wiki_dump() {
    echo "$(date +"%T"): try to load wiki dump.."
    local file_name="$IMPORT_DATA_DIR/wikipedia_article.sql.bin"
    #wget --output-document=$IMPORT_DATA_DIR/wikipedia_redirect.sql.bin http://www.nominatim.org/data/wikipedia_redirect.sql.bin

    exec_psql_file "wiki_privileges.sql" "postgres"

    if [ ! -f "$file_name" ]; then
        wget --output-document=$file_name http://www.nominatim.org/data/wikipedia_article.sql.bin
    fi
    pg_restore -h $DB_HOST -d $DB_NAME -p $DB_PORT -U brian $file_name
    #pg_restore -h $DB_HOST -d $DB_NAME -p $DB_PORT -U brian $IMPORT_DATA_DIR/wikipedia_redirect.sql.bin
    echo "$(date +"%T"): wiki data complete.."
    exec_psql_file "wiki_transfer_ownership.sql" "postgres"
    
}

function main() {
    if [ "$(ls -A $IMPORT_DATA_DIR/*.pbf 2> /dev/null)" ]; then
        local pbf_file
        for pbf_file in "$IMPORT_DATA_DIR"/*.pbf; do
            import_pbf "$pbf_file"
            break
        done
        load_wiki_dump
        indexing_phase
    else
        echo "No PBF files for import found."
        echo "Please mount the $IMPORT_DATA_DIR volume to a folder containing OSM PBF files."
        exit 404
    fi
}

main
