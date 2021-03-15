#!/usr/bin/env bash

# Install prerequisites
sudo yum install -y htop docker

# Set up docker and get Rumble
sudo service docker start
sudo usermod -a -G docker ec2-user
sudo docker pull rumbledb/rumble:latest

export _JAVA_OPTIONS="-Xmx14g"
docker run --rm -d --cpuset-cpus 0 \
		   --memory="14g" --expose 8001 \
		   -p 8001:8001 -e _JAVA_OPTIONS="-Xmx14g" \
		   -e SPARK_SUBMIT_OPTIONS="--driver-memory 14 --conf spark.sql.shuffle.partitions=10" \
		   -v /data:/data/:ro rumbledb/rumble:v1.11.0-spark3 \
		   --server yes --host 0.0.0.0

# Get the queries and the data
cd /data 
git clone https://github.com/DanGraur/hep-iris-benchmark-jsoniq.git
cd hep-iris-benchmark-jsoniq
python3 -m pip install --user -r requirements.txt
cd ..
aws s3 cp s3://hep-adl-ethz/hep-parquet/ . --recursive --include "*.parquet"
cp -r ~/hep-iris-benchmark-jsoniq .
cd ~