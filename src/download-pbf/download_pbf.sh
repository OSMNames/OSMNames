#!/bin/bash
set -o errexit
set -o pipefail
set -o nounset

readonly FILE_URL="http://download.geofabrik.de/europe/andorra-latest.osm.pbf"


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

function download_file() {
    echo "$(date +"%T"): downloading file.."
        wget $FILE_URL -P $EXPORT_DIR
}

function main() {
        download_file
}

main
