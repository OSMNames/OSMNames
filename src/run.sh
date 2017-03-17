#!/bin/bash
set -o errexit
set -o pipefail
set -o nounset

until psql --username=postgres postgres -c "select 1" > /dev/null 2>&1; do
  echo "Waiting for postgres server"
  sleep 2
done

. './shared/functions.sh'

(cd 'init-database'; ./init-database.sh)
(cd 'download-pbf'; ./download-pbf.sh)
(cd 'import-wikipedia'; ./import-wikipedia.sh)
(cd 'import-osm'; ./import-osm.sh)
(cd 'export-osmnames'; ./export-osmnames.sh)
