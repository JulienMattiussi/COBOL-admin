FROM ubuntu:24.04

RUN apt-get update && \
    apt-get install -y gnucobol4 curl jq && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Download gcblunit test framework
ADD https://raw.githubusercontent.com/OlegKunitsyn/gcblunit/master/gcblunit.cbl gcblunit.cbl

COPY . .

# Compile modules as object files
RUN cobc -free -c -I copybooks schema-loader.cbl
RUN cobc -free -c -I copybooks http-parse.cbl
RUN cobc -free -c -I copybooks router.cbl
RUN cobc -free -c -I copybooks page-layout.cbl
RUN cobc -free -c -I copybooks page-home.cbl
RUN cobc -free -c -I copybooks page-list.cbl
RUN cobc -free -c -I copybooks page-404.cbl
RUN cobc -free -c -I copybooks pagination.cbl
RUN cobc -free -c -I copybooks serve-static.cbl

# Compile and link main with all modules
RUN cobc -free -x -I copybooks -o cobol-admin \
    main.cbl \
    schema-loader.o \
    http-parse.o \
    router.o \
    page-layout.o \
    page-home.o \
    page-list.o \
    page-404.o \
    pagination.o \
    serve-static.o

# Run tests at build time
RUN chmod +x run-tests.sh && ./run-tests.sh

EXPOSE 8080
CMD ["./cobol-admin"]
