FROM golang:1.8

RUN echo 'deb http://apt.postgresql.org/pub/repos/apt/ jessie-pgdg main' >> /etc/apt/sources.list && \
    wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -

RUN DEBIAN_FRONTEND=noninteractive apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
      libprotobuf-dev \
      libleveldb-dev \
      libgeos-dev \
      postgresql-client-10 \
      python-pip \
      python-psycopg2 \
 && ln -s /usr/lib/libgeos_c.so /usr/lib/libgeos.so \
 && rm -rf /var/lib/apt/lists/*

RUN pip install --upgrade pip
RUN pip install -U setuptools

RUN go get github.com/omniscale/imposm3 \
 && go install github.com/omniscale/imposm3/cmd/imposm

# Purge no longer needed packages to keep image small.
# Protobuf and LevelDB dependencies cannot be removed
# because they are dynamically linked.
RUN apt-get purge -y --auto-remove \
      g++ gcc libc6-dev make git \
      && rm -rf /var/lib/apt/lists/*

ADD . /osmnames
WORKDIR /osmnames

RUN pip install -r requirements.txt.lock

CMD ["./run.py"]
