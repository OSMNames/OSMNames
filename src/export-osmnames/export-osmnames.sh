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

function prepare_data() {
    echo "$(date +"%T"): collecting polygons.."
    exec_psql_file "01_polygons.sql" "$DB_USER"
    echo "$(date +"%T"): collecting points.."
    exec_psql_file "02_points.sql" "$DB_USER"
    echo "$(date +"%T"): collecting linestrings"
    exec_psql_file "03_linestrings.sql" "$DB_USER"
    echo "$(date +"%T"): collecting merged linestrings.."
    exec_psql_file "04_merged_linestrings.sql" "$DB_USER"
}

function cleanup() {
    exec_psql_file "05_cleanup.sql" "$DB_USER"
}

function export_geonames() {
    exec_psql_file "functions.sql" "$DB_USER"
    echo "$(date +"%T"): start export.."
    filename=$(determineOutputFilename)
    cleanup
    prepare_data
    echo "$(date +"%T"): writing tsv file.."
    export_tsv "$filename.tsv" "export.sql"
    cleanup
    echo "$(date +"%T"): export finished. Zipping output file.."
    gzip_tsv "$filename.tsv"
}

export_geonames