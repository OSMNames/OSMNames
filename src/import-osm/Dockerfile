FROM golang:1.7

WORKDIR $GOPATH

# Purge no longer needed packages at the end to keep image small.
# Protobuf and LevelDB dependencies cannot be removed
# because they are dynamically linked.
RUN DEBIAN_FRONTEND=noninteractive apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    postgresql-client \
    && rm -rf /var/lib/apt/lists/*

RUN wget -O imposm3.tar.gz https://imposm.org/static/rel/imposm3-0.3.0dev-20170119-353bc5d-linux-x86-64.tar.gz \
    && tar -xf imposm3.tar.gz -C /tmp \
    && mv /tmp/imposm3-* /opt/imposm3

ENV PATH $PATH:/opt/imposm3

VOLUME /data/import /data/cache
ENV IMPORT_DATA_DIR=/data/import \
    IMPOSM_CACHE_DIR=/data/cache \
    MAPPING_YAML=/usr/src/app/mapping.yml

WORKDIR /usr/src/app
COPY . /usr/src/app/

CMD ["./import-osm.sh"]
