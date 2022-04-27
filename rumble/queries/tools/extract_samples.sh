#!/usr/bin/env bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
ROOT_DIR="$SCRIPT_DIR/.."

# Change the following variables according to your system or make sure that
# these executables are in your path:
ROOTEVENTSELECTOR=rooteventselector
SPARK_SUBMIT=spark-submit

for l in {0..16}
do
    n=$((2**$l*1000))
    echo "Extracting sample of $n events..."

    # Extract first $n events and store as ROOT file
    $ROOTEVENTSELECTOR -f 0 -l $(($n-1)) \
        "$ROOT_DIR/data/Run2012B_SingleMu.root:Events" \
        "$ROOT_DIR/data/Run2012B_SingleMu_$n.root"

    # Convert to Parquet file as exposed by Laurelin
    $SPARK_SUBMIT --packages edu.vanderbilt.accre:laurelin:1.1.1 \
        "$ROOT_DIR/tools/root2parquet.py" \
        -i "$ROOT_DIR/data/Run2012B_SingleMu_$n.root" \
        -o "$ROOT_DIR/data/Run2012B_SingleMu_$n.parquet"

    # Restucture as "array of structs" (aka "native objects")
    $SPARK_SUBMIT "$ROOT_DIR/tools/restructure.py" \
        -i "$ROOT_DIR/data/Run2012B_SingleMu_$n.parquet" \
        -o "$ROOT_DIR/data/Run2012B_SingleMu_restructured_$n.parquet"
done
