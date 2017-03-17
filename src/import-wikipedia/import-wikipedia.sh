#!/bin/bash
set -o errexit
set -o pipefail
set -o nounset

# credits to nominatim for providing the precalculated data
readonly WIKIPEDIA_ARTICLE_TABLE="http://www.nominatim.org/data/wikipedia_article.sql.bin"

function load_wiki_dump() {
    echo "$(date +"%T"): try to load wikipedia dump.."
    local file_name="$IMPORT_DIR/wikipedia_article.sql.bin"
    exec_psql_file "wiki_privileges.sql" "postgres"
    if [ ! -f "$file_name" ]; then
        wget --output-document=$file_name $WIKIPEDIA_ARTICLE_TABLE
    fi
    pg_restore --dbname=$DB_NAME -U brian $file_name
    echo "$(date +"%T"): wikipedia loading complete.."
    exec_psql_file "wiki_transfer_ownership.sql" "postgres"
    exec_psql_file "create_index.sql" "postgres"
}

function main() {
  if psql -c "SELECT 1 FROM wikipedia_article;" > /dev/null 2>&1; then
    echo "Skipping wikipedia import, since it seems already imported"
    return
  fi

  load_wiki_dump
}

main
