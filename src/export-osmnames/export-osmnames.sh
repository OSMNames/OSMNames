#!/bin/bash
set -o errexit
set -o pipefail
set -o nounset

readonly DB_HOST=$DB_PORT_5432_TCP_ADDR
readonly DB_PORT=$DB_PORT_5432_TCP_PORT
readonly EXPORT_DIR=${EXPORT_DIR:-"/data/"}

readonly IMPORT_DATA_DIR=${IMPORT_DATA_DIR:-/data}


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

function gzip_tsv() {
    local tsv_filename="$1"
    local tsv_file="$EXPORT_DIR/$tsv_filename"
    gzip -c "$tsv_file" > "$tsv_file.gz"
}

function determineOutputFilename() {
    if [ "$(ls -A $IMPORT_DATA_DIR/*.pbf 2> /dev/null)" ]; then
    filename=$(ls -t -U $IMPORT_DATA_DIR/**.pbf | xargs -n1 basename | sed -e 's/\..*$//')
    echo "$filename"
    else
        echo "output"
    fi
    return
}

function export_geonames() {
    echo "$(date +"%T"): start export.."
    filename=$(determineOutputFilename)
    export_tsv "$filename.tsv" "export.sql"
    echo "$(date +"%T"): export finished. Zipping output file.."
    gzip_tsv "$filename.tsv"
}

export_geonames