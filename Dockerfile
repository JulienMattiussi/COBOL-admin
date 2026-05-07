# syntax=docker/dockerfile:1

# ---- Stage 1: build the COBOL binary ----
FROM ubuntu:24.04 AS cobol-builder

RUN apt-get update && apt-get install -y \
    gnucobol4 \
    libcurl4-openssl-dev \
    gcc \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /build

ADD https://raw.githubusercontent.com/OlegKunitsyn/gcblunit/master/gcblunit.cbl gcblunit.cbl
ADD https://raw.githubusercontent.com/DaveGamble/cJSON/master/cJSON.c cJSON.c
ADD https://raw.githubusercontent.com/DaveGamble/cJSON/master/cJSON.h cJSON.h

COPY cobol/ ./

RUN gcc -c -fPIC -o helpers.o helpers.c -I. && \
    gcc -c -fPIC -o cJSON.o cJSON.c

RUN cobc -free -c -I copybooks template-engine.cbl && \
    cobc -free -c -I copybooks schema-loader.cbl && \
    cobc -free -c -I copybooks http-parse.cbl && \
    cobc -free -c -I copybooks router.cbl && \
    cobc -free -c -I copybooks page-layout.cbl && \
    cobc -free -c -I copybooks page-home.cbl && \
    cobc -free -c -I copybooks page-list.cbl && \
    cobc -free -c -I copybooks page-404.cbl && \
    cobc -free -c -I copybooks pagination.cbl && \
    cobc -free -c -I copybooks page-show.cbl && \
    cobc -free -c -I copybooks page-edit.cbl && \
    cobc -free -c -I copybooks form-submit.cbl && \
    cobc -free -c -I copybooks serve-static.cbl && \
    cobc -free -c -I copybooks html-escape.cbl && \
    cobc -free -c -I copybooks shell-sanitize.cbl && \
    cobc -free -c -I copybooks fetch-item.cbl && \
    cobc -free -c -I copybooks ref-detect.cbl && \
    cobc -free -c -I copybooks page-create.cbl && \
    cobc -free -c -I copybooks form-create.cbl && \
    cobc -free -c -I copybooks page-delete.cbl

RUN cobc -free -x -I copybooks -o cobol-admin \
    main.cbl \
    template-engine.o schema-loader.o http-parse.o router.o \
    page-layout.o page-home.o page-list.o page-404.o pagination.o \
    page-show.o page-edit.o form-submit.o serve-static.o \
    html-escape.o shell-sanitize.o fetch-item.o ref-detect.o \
    page-create.o form-create.o page-delete.o helpers.o cJSON.o \
    -lcurl

# ---- Stage 2: runtime with Node + COBOL binary ----
FROM ubuntu:24.04

RUN apt-get update && apt-get install -y \
    gnucobol4 \
    libcurl4 \
    nodejs \
    npm \
    curl \
    ca-certificates \
    tini \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY server/package.json server/package-lock.json ./server/
RUN cd server && npm ci --omit=dev

COPY server/ ./server/

COPY --from=cobol-builder /build/cobol-admin ./cobol/cobol-admin
COPY cobol/templates ./cobol/templates
COPY cobol/static ./cobol/static

COPY start.sh ./
RUN chmod +x start.sh

EXPOSE 8080

ENTRYPOINT ["/usr/bin/tini", "--"]
CMD ["./start.sh"]
