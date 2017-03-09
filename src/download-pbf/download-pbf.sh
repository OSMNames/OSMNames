#!/bin/bash
set -o errexit
set -o pipefail
set -o nounset

readonly FILE_URL="http://download.geofabrik.de/europe/switzerland-latest.osm.pbf"
readonly EXPORT_DIR="${DATA_DIR}/export/"

echo "$(date +"%T"): downloading file.."
wget $FILE_URL -P $EXPORT_DIR
