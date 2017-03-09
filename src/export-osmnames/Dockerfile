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

VOLUME /data
ENV EXPORT_DIR="/data"

WORKDIR /usr/src/app
COPY . /usr/src/app
CMD ["./export-osmnames.sh"]
