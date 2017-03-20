#!/bin/bash
set -o errexit
set -o pipefail
set -o nounset

until psql --username=postgres postgres -c "select 1" > /dev/null 2>&1; do
  echo "Waiting for postgres server"
  sleep 2
done

python -m cProfile -o cprofile.log run.py
