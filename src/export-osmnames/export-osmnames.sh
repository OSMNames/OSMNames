#!/bin/bash
set -o errexit
set -o pipefail
set -o nounset

readonly DB_HOST=$DB_PORT_5432_TCP_ADDR
readonly DB_PORT=$DB_PORT_5432_TCP_PORT
readonly EXPORT_DIR=${EXPORT_DIR:-"/data/"}

function export_tsv() {
    local tsv_filename="$1"
    local tsv_file="$EXPORT_DIR/$tsv_filename"
    local sql_file="$2"

    pgclimb \
        -f "$sql_file" \
        -o "$tsv_file" \
        -dbname "$DB_NAME" \
        --username "$DB_USER" \
        --host "$DB_HOST" \
        --port "$DB_PORT" \
        --pass "$DB_PASSWORD" \
    tsv --header
}

function export_geonames() {
    export_tsv "roads.tsv" "roads.sql"
    export_tsv "cities.tsv" "cities.sql"
}

export_geonames
