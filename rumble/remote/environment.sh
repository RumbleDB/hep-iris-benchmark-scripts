#!/usr/bin/env bashHmmm, ok 

# Install prerequisites
sudo yum install -y htop docker

# Set up docker and run rumble
sudo service docker start
sudo usermod -a -G docker ec2-user
sudo docker pull rumbledb/rumble:latest

export _JAVA_OPTIONS="-Xmx14g"
docker run --rm -d --name "my-rumble"\
	       --memory="14g" --expose 8001 --expose 4040 --expose 18080 \
	       -p 8001:8001 -p 4040:4040 -p 18080:18080 -e _JAVA_OPTIONS="-Xmx14g" \
		   -e SPARK_SUBMIT_OPTIONS="--driver-memory 14 --conf spark.sql.shuffle.partitions=10" \
		   -v /data:/data/: rumbledb/rumble:v1.11.0-spark3 \
		   --server yes --host 0.0.0.0
wait

mkdir -p /data/native && cd /data/native && aws s3 cp s3://hep-adl-ethz/hep-parquet/native . --recursive --include "*.parquet"