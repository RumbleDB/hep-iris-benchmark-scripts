SCRIPTPATH:=$(dir $(realpath $(lastword $(MAKEFILE_LIST))))

PARQUET2JSON=$(SCRIPTPATH)/parquet2json.py

PARQUET_FILES=$(wildcard *.[0-9][0-9][0-9].parquet)
JSON_FILES=$(PARQUET_FILES:=.json.gz)

.DELETE_ON_ERROR:

all: $(JSON_FILES)

%.json.gz: %
	$(PARQUET2JSON) -i $<  -o /dev/stdout | gzip > $@
