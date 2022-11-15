FROM golang:1.19.3-bullseye

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update
RUN apt-get install curl ca-certificates gnupg -y

RUN echo 'deb http://apt.postgresql.org/pub/repos/apt/ buster-pgdg main' >> /etc/apt/sources.list && \
    curl https://www.postgresql.org/media/keys/ACCC4CF8.asc | gpg --dearmor | tee /etc/apt/trusted.gpg.d/apt.postgresql.org.gpg >/dev/null

RUN apt-get install -y --no-install-recommends \
      libprotobuf-dev \
      libleveldb-dev \
      libpq-dev \
      libgeos-dev \
      postgresql-client-13 \
      python3-pip \
      python3-dev \
&& ln -s /usr/lib/libgeos_c.so /usr/lib/libgeos.so \
&& rm -rf /var/lib/apt/lists/*

RUN pip3 install --upgrade pip
RUN pip3 install -U setuptools

RUN go install github.com/omniscale/imposm3/cmd/imposm@latest

RUN git clone https://github.com/gbb/par_psql && \
    cd par_psql && ./install.sh

ADD . /osmnames
WORKDIR /osmnames

RUN pip3 install -r requirements.txt

# Purge no longer needed packages to keep image small.
# Protobuf and LevelDB dependencies cannot be removed
# because they are dynamically linked.
RUN apt-get purge -y --auto-remove \
      g++ gcc libc6-dev make git \
      && rm -rf /var/lib/apt/lists/*

CMD ["./run.py"]