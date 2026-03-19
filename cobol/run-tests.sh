#!/bin/bash
set -e

echo "=== Compiling modules ==="
cobc -free -c -I copybooks http-parse.cbl
cobc -free -c -I copybooks router.cbl
cobc -free -c -I copybooks page-layout.cbl
cobc -free -c -I copybooks page-home.cbl
cobc -free -c -I copybooks page-list.cbl
cobc -free -c -I copybooks page-404.cbl
cobc -free -c -I copybooks pagination.cbl
cobc -free -c -I copybooks page-show.cbl
cobc -free -c -I copybooks serve-static.cbl

echo "=== Running tests ==="
cobc -x -free -debug -I copybooks \
    gcblunit.cbl \
    tests/test-http-parse.cbl \
    tests/test-router.cbl \
    tests/test-pages.cbl \
    http-parse.o \
    router.o \
    page-layout.o \
    page-home.o \
    page-list.o \
    page-404.o \
    pagination.o \
    page-show.o \
    serve-static.o \
    --job='test-http-parse test-router test-pages'
