FROM golang:1.19.3-bullseye

# ARG is only set for the build
ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install curl ca-certificates gnupg -y

RUN apt-get install -y --no-install-recommends \
      libprotobuf-dev \
      libleveldb-dev \
      libpq-dev \
      libgeos-dev \
      postgresql-client \
      python3-pip \
      python3-dev \
&& ln -s /usr/lib/libgeos_c.so /usr/lib/libgeos.so \
&& rm -rf /var/lib/apt/lists/*

RUN pip3 install --upgrade pip
RUN pip3 install -U setuptools

RUN go install github.com/omniscale/imposm3/cmd/imposm@latest

RUN git clone https://github.com/gbb/par_psql && \
    cd par_psql && ./install.sh

ADD requirements.txt.lock /osmnames/requirements.txt.lock
WORKDIR /osmnames
RUN pip3 install -r requirements.txt.lock

# Purge no longer needed packages to keep image small.
# Protobuf and LevelDB dependencies cannot be removed
# because they are dynamically linked.
RUN apt-get purge -y --auto-remove \
      g++ gcc libc6-dev make git \
      && rm -rf /var/lib/apt/lists/*

ADD . /osmnames

CMD ["./run.py"]
