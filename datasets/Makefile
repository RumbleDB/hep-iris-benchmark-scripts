SCRIPTPATH:=$(dir $(realpath $(lastword $(MAKEFILE_LIST))))
REPOROOTDIR:=$(realpath $(SCRIPTPATH)/../)

#
# Input file
#
XROOTD_IMAGE = rucio/xrootd@sha256:9b787e0e2e9e2db04dd156bb13b378fae2e9ad2658fff7e0b2d5d39aaebb2d3f
XRDCP = docker run --rm -v$(SCRIPTPATH):$(SCRIPTPATH) --workdir $(SCRIPTPATH) --entrypoint /usr/bin/xrdcp $(XROOTD_IMAGE)
INPUTURL = root://eospublic.cern.ch//eos/root-eos/benchmark/Run2012B_SingleMu.root

#
# Extract scale factor <1
#
ROOT_IMAGE = rootproject/root:6.24.02-ubuntu20.04
ROOTEVENTSELECTOR = docker run --rm -v$(SCRIPTPATH):$(SCRIPTPATH) --workdir $(SCRIPTPATH) $(ROOT_IMAGE) rooteventselector

#
# Convert ROOT to Parquet
#
PYSPARK_IMAGE = jupyter/pyspark-notebook:spark-2
SPARK_SUBMIT = docker run --rm -v$(REPOROOTDIR):$(REPOROOTDIR) -e NB_UID=$$(id -u) -e NB_GID=$$(id -g) --user root --workdir $(SCRIPTPATH) $(PYSPARK_IMAGE) /usr/local/bin/start.sh /usr/local/spark/bin/spark-submit
ROOT2PARQUET = $(SPARK_SUBMIT) --packages edu.vanderbilt.accre:laurelin:1.1.1 --driver-memory $$(($$(grep MemTotal /proc/meminfo | grep -oE "[0-9]*")/2))k $(REPOROOTDIR)/experiments/rumble/queries/tools/root2parquet.py

#
# Restructure shredded to native format
#
RESTRUCTURE = $(SPARK_SUBMIT) $(REPOROOTDIR)/experiments/rumble/queries/tools/restructure.py

#
# Enumerate target files
#
SUBSETS = 1000 2000 4000 8000 16000 32000 64000 128000 256000 512000 1024000 2048000 4096000 8192000 16384000 32768000 65536000
ROOT_FILES = $(patsubst %, Run2012B_SingleMu_%.root, $(SUBSETS))
SHREDDED_PARQUET_FILES = $(ROOT_FILES:.root=.parquet)
NATIVE_PARQUET_FILES = $(patsubst %, Run2012B_SingleMu_restructured_%.parquet, $(SUBSETS))

all: $(ROOT_FILES) $(SHREDDED_PARQUET_FILES) $(NATIVE_PARQUET_FILES)

Run2012B_SingleMu.root:
	$(XRDCP) $(INPUTURL) $@

Run2012B_SingleMu_%.root: Run2012B_SingleMu.root
	$(ROOTEVENTSELECTOR) -l $$(($(patsubst Run2012B_SingleMu_%.root, %, $@)-1)) $^:Events $@

%.parquet: %.root
	rm -rf $@
	$(ROOT2PARQUET) --input $^ --output $@
	mv $@ $@.dir
	mv $@.dir/*.parquet $@
	rm -rf $@.dir

Run2012B_SingleMu_restructured_%.parquet: Run2012B_SingleMu_%.parquet
	rm -rf $@
	$(RESTRUCTURE) --input $^ --output $@
	mv $@ $@.dir
	mv $@.dir/*.parquet $@
	rm -rf $@.dir
