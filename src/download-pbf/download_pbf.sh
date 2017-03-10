#!/bin/bash
set -o errexit
set -o pipefail
set -o nounset

readonly FILE_URL="http://mirror2.shellbot.com/osm/planet-latest.osm.pbf"



function download_file() {
    echo "$(date +"%T"): downloading file.."
        wget $FILE_URL -P $EXPORT_DIR
}

function main() {
        download_file
}

main
