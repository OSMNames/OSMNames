FROM golang:1.7

WORKDIR $GOPATH

# Purge no longer needed packages at the end to keep image small.
# Protobuf and LevelDB dependencies cannot be removed
# because they are dynamically linked.
RUN DEBIAN_FRONTEND=noninteractive apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
      libprotobuf-dev \
      libleveldb-dev \
      libgeos-dev \
      postgresql-client \
      autoconf \
      automake \
      libtool \
      --no-install-recommends \
 && ln -s /usr/lib/libgeos_c.so /usr/lib/libgeos.so \
 && git clone https://github.com/rescrv/HyperLevelDB.git /opt/HyperLevelDB \
 && cd /opt/HyperLevelDB \
 && autoreconf -i && ./configure \
 && make && make install && ldconfig

RUN go get -d -x github.com/omniscale/imposm3
RUN echo '##########################'
RUN go install -x -v github.com/omniscale/imposm3

RUN apt-get purge -y --auto-remove \
    g++ gcc libc6-dev make git autoconf automake libtool \
    && rm -rf /var/lib/apt/lists/*

VOLUME /data/import /data/cache
ENV IMPORT_DATA_DIR=/data/import \
    IMPOSM_CACHE_DIR=/data/cache \
    MAPPING_YAML=/usr/src/app/mapping.yml

WORKDIR /usr/src/app
COPY . /usr/src/app/

CMD ["./import-osm.sh"]
