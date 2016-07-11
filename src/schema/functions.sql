CREATE TYPE parentInfo AS (
    state           TEXT,
    county          TEXT,
    city 			TEXT,
    displayName		TEXT
);

CREATE TYPE rankPartitionCode AS (
    rank_search           integer,
    partition           integer,
    calculated_country_code character varying(2)
);