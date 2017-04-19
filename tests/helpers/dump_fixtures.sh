#!/bin/bash

pg_dump --no-owner --schema-only --schema="public" --clean --if-exists -t 'osm_*' osm > $1
