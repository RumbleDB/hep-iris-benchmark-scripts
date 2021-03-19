#!/usr/bin/bash

SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"

for q in 1 2 3 4 5 6-1 6-2 7 8-1 8-2
do
    flags=""
    if [[ "$q" != "1" && "$q" != "5" ]]; then flags="$flags -y"; fi
    if [[ "$q" != "4" ]]; then flags="$flags -l"; fi
    if [[ "$q" -le 4 ]]; then flags="$flags -x"; fi
    $SOURCE_DIR/cost-running-time-tradeoff.py \
        -q $q $flags \
        -i $SOURCE_DIR/common.json \
        -o $SOURCE_DIR/cost-running-time-tradeoff-$q.pdf
done
