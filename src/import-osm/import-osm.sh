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

function init_helper_tables() {
    echo "$(date +"%T"): init helper tables"
    exec_psql_file "create_hstore.sql" "postgres"
    exec_psql_file "$IMPORT_DATA_DIR/sql/country_name.sql" "postgres"
    exec_psql_file "$IMPORT_DATA_DIR/sql/country_osm_grid.sql" "postgres"
    exec_psql_file "create_merged_linestring_table.sql" "postgres"
    exec_psql_file "alter_imposm_tables.sql" "$DB_USER"
}

function indexing_phase() {
    echo "$(date +"%T"): start indexing.."
    exec_psql_file "indexing.sql" "$DB_USER"
    echo "$(date +"%T"): indexing complete.."
}

function reading_pbf_file() {
 if [ "$(ls -A $IMPORT_DATA_DIR/*.pbf 2> /dev/null)" ]; then
        local pbf_file
        for pbf_file in "$IMPORT_DATA_DIR"/*.pbf; do
            import_pbf "$pbf_file"
            break
        done
        return 0
    else
        echo "No PBF files for import found."
        echo "Please mount the $IMPORT_DATA_DIR volume to a folder containing OSM PBF files."
        exit 404
    fi
} 

function main() {
    reading_pbf_file
    #retval=$?
    #if [ "$retval" == 0 ]; then
        init_helper_tables
        indexing_phase
    #fi
}

main
