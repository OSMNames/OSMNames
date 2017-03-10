FROM golang:1.8

RUN go get github.com/lukasmartinelli/pgclimb \
 && go install github.com/lukasmartinelli/pgclimb

RUN DEBIAN_FRONTEND=noninteractive apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
      libprotobuf-dev \
      libleveldb-dev \
      libgeos-dev \
      postgresql-client \
      --no-install-recommends \
 && ln -s /usr/lib/libgeos_c.so /usr/lib/libgeos.so \
 && rm -rf /var/lib/apt/lists/*

RUN go get github.com/omniscale/imposm3
RUN go install github.com/omniscale/imposm3/cmd/imposm3

# Purge no longer needed packages to keep image small.
# Protobuf and LevelDB dependencies cannot be removed
# because they are dynamically linked.
RUN apt-get purge -y --auto-remove \
      g++ gcc libc6-dev make git \
      && rm -rf /var/lib/apt/lists/*

ADD . /osmnames
WORKDIR /osmnames/src

CMD ["./run.sh"]
