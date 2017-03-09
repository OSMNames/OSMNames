#!/bin/bash
set -o errexit
set -o pipefail
set -o nounset

TIMEOUT=5
until psql postgres -c "select 1" > /dev/null 2>&1 || [ $TIMEOUT -eq 0 ]; do
  echo "Waiting for postgres server, $((TIMEOUT--)) remaining attempts..."
  sleep 3
done

. './shared/functions.sh'

(cd 'init-database'; ./init-database.sh)
(cd 'download-pbf'; ./download-pbf.sh)
(cd 'import-wikipedia'; ./import-wikipedia.sh)
(cd 'import-osm'; ./import-osm.sh)
(cd 'export-osmnames'; ./export-osmnames.sh)
