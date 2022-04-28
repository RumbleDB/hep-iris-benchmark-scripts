#!/usr/bin/env bash


FULL_DATASET=s3://hep-adl-ethz/hep-parquet/native/Run2012B_SingleMu-65536000.parquet/
AWS_BUCKET=s3://hep-adl-ethz/hep-parquet/native-sf 


for i in {1..6}
do
	SF=$(( 2 ** ${i} ))
	AWS_SF_BUCKET=${AWS_BUCKET}
	for j in `seq 1 1 ${SF}`
	do
		aws s3 sync ${FULL_DATASET} ${AWS_SF_BUCKET}/${SF}/${j}.parquet > logs/${SF}_${j}.log 2>&1 &
	done
done