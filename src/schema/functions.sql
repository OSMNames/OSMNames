CREATE TYPE rankPartitionCode AS (
    rank_search           integer,
    partition           integer,
    calculated_country_code character varying(2)
);