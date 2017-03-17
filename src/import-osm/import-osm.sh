#!/bin/bash
set -o errexit
set -o pipefail
set -o nounset

readonly MAPPING_YAML="mapping.yml"

readonly PG_CONNECT="postgis://$PGUSER@$PGHOST/$DB_NAME"

function import_pbf() {
    local pbf_file="$1"
    imposm3 import \
        -connection "$PG_CONNECT" \
        -mapping "$MAPPING_YAML" \
        -overwritecache \
        -cachedir "$CACHE_DIR" \
        -read "$pbf_file" \
        -dbschema-import="${DB_SCHEMA}" \
        -write
}

function init_helper_tables() {
    echo "$(date +"%T"): init helper tables"
    exec_psql_file "$DATA_DIR/sql/country_name.sql" "postgres"
    exec_psql_file "$DATA_DIR/sql/country_osm_grid.sql" "postgres"
    exec_psql_file "00_index_helper_tables.sql"

}

function indexing_phase() {
    echo "$(date +"%T"): delete  unusable entries.."
    exec_psql_file "01_delete_unusable_entries.sql"
    echo "$(date +"%T"): initiate ranking and partitioning.."
    exec_psql_file "02_ranking_partitioning.sql"
    echo "$(date +"%T"): determine linked places.."
    exec_psql_file "03_determine_linked_places.sql"
    echo "$(date +"%T"): creating hierarchy.."
    exec_psql_file "04_create_hierarchy.sql"
    echo "$(date +"%T"): merging corresponding streets.."
    exec_psql_file "05_merge_corresponding_streets.sql"
    echo "$(date +"%T"): indexing complete.."
}

function init_functions() {
    echo "$(date +"%T"): init functions"
    exec_psql_file "functions.sql"
}

function reading_pbf_file() {
 if [ "$(ls -A $IMPORT_DIR/*.pbf 2> /dev/null)" ]; then
        local pbf_file
        for pbf_file in "$IMPORT_DIR"/*.pbf; do
            import_pbf "$pbf_file"
            break
        done
        return 0
    else
        echo "No PBF files for import found."
        echo "Please mount the $IMPORT_DIR volume to a folder containing OSM PBF files."
        exit 404
    fi
}

function main() {
    reading_pbf_file
    retval=$?
    if [ "$retval" == 0 ]; then
        init_helper_tables
        init_functions
        indexing_phase
    fi
}

main
