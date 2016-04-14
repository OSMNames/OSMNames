#!/bin/bash
set -o errexit
set -o pipefail
set -o nounset

readonly OSM_HOST=$DB_PORT_5432_TCP_ADDR
readonly OSM_PORT=$DB_PORT_5432_TCP_PORT
readonly OSM_DB=${OSM_DB:-osm}
readonly OSM_USER=${OSM_USER:-osm}
readonly OSM_PASSWORD=${OSM_PASSWORD:-osm}
readonly EXPORT_DIR=${EXPORT_DIR:-"./"}

function export_tsv() {
    local tsv_filename="$1"
    local tsv_file="$EXPORT_DIR/$tsv_filename"
    local sql_file="$2"

	pgclimb \
        -f "$sql_file" \
        -o "$tsv_file" \
        -dbname "$OSM_DB" \
        --username "$OSM_USER" \
        --host "$OSM_HOST" \
        --port "$OSM_PORT" \
        --pass "$OSM_PASSWORD" \
    tsv --header
}

function export_geonames() {
    export_tsv "roads.tsv" "roads.sql"
}

export_geonames
