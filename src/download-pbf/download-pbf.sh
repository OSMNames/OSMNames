#!/bin/bash
set -o errexit
set -o pipefail
set -o nounset

readonly FILE_NAME="switzerland-latest.osm.pbf"
readonly FILE_URL="http://download.geofabrik.de/europe/${FILE_NAME}"
readonly EXPORT_DIR="${DATA_DIR}/export/"

if [ ! -f "$EXPORT_DIR/$FILE_NAME" ]; then
  echo "$(date +"%T"): downloading file.."
  wget $FILE_URL -P $EXPORT_DIR
else
  echo "download of $FILE_NAME skipped, since it exists"
fi
