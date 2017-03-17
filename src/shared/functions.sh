#!/bin/bash

function exec_psql_file() {
    local filename="$1"
    local username="${2:-$PGUSER}"
    psql -v ON_ERROR_STOP=1 \
         -A -t --variable="FETCH_COUNT=10000" \
         --username="$username" \
         --dbname="$DB_NAME" \
         -f "$filename"
}

export -f exec_psql_file
