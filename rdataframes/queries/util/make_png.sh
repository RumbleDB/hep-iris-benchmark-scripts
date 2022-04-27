#!/bin/bash

for root_file in "$@"
do
	root -b -l <<EOF
	TFile f("$root_file");
	c1->SaveAs("$(basename -s .root "$root_file").png")
EOF
done
