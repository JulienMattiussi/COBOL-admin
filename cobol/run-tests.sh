#!/bin/bash
set -e

echo "=== Compiling modules ==="
cobc -free -c -I copybooks template-engine.cbl
cobc -free -c -I copybooks http-parse.cbl
cobc -free -c -I copybooks router.cbl
cobc -free -c -I copybooks page-layout.cbl
cobc -free -c -I copybooks page-home.cbl
cobc -free -c -I copybooks page-list.cbl
cobc -free -c -I copybooks page-404.cbl
cobc -free -c -I copybooks pagination.cbl
cobc -free -c -I copybooks page-show.cbl
cobc -free -c -I copybooks page-edit.cbl
cobc -free -c -I copybooks form-submit.cbl
cobc -free -c -I copybooks serve-static.cbl
cobc -free -c -I copybooks html-escape.cbl

echo "=== Running tests ==="
cobc -x -free -debug -I copybooks \
    gcblunit.cbl \
    tests/test-http-parse.cbl \
    tests/test-router.cbl \
    tests/test-pages.cbl \
    tests/test-html-escape.cbl \
    template-engine.o \
    http-parse.o \
    router.o \
    page-layout.o \
    page-home.o \
    page-list.o \
    page-404.o \
    pagination.o \
    page-show.o \
    page-edit.o \
    form-submit.o \
    serve-static.o \
    html-escape.o \
    --job='test-http-parse test-router test-pages test-html-escape'
