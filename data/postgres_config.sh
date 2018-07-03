#!/bin/bash
set -o errexit
set -o pipefail
set -o nounset

function alter_system() {
    echo "Altering System parameters"
    PGUSER="$POSTGRES_USER" psql --dbname="$POSTGRES_DB" <<-EOSQL

    -- add your postgres configuration here
    -- recommended: https://pgtune.leopard.in.ua/
    -- with alter system option
EOSQL
}

alter_system
