#!/usr/bin/env bash

# Install prerequisites
sudo yum install -y git maven htop python3 docker

# Set up Java
wget --no-cookies --no-check-certificate --header "Cookie: oraclelicense=accept-securebackup-cookie" https://javadl.oracle.com/webapps/download/GetFile/1.8.0_271-b09/61ae65e088624f5aaa0b1d2d801acb16/linux-i586/jdk-8u271-linux-x64.tar.gz
tar xzf jdk-8u271-linux-x64.tar.gz 
cd jdk1.8.0_271
cd -

# Set up Spark
wget https://downloads.apache.org/spark/spark-3.0.2/spark-3.0.2-bin-hadoop2.7.tgz
tar xzf spark-3.0.2-bin-hadoop2.7.tgz

# Get Rumble
git clone https://github.com/RumbleDB/rumble.git
cd rumble
git checkout 64ff255e8103ebef5257006e252e04943dbeb415
mvn clean compile assembly:single -T 4 -DskipTests
cp target/spark-rumble-1.10.0-jar-with-dependencies.jar ..
cd ..
mv spark-rumble-1.10.0-jar-with-dependencies.jar spark-rumble-1.10.0-for-spark-3.jar


# Get the queries and the data
cd /data 
git clone https://github.com/RumbleDB/hep-iris-benchmark-jsoniq
cd hep-iris-benchmark-jsoniq
python3 -m pip install --user -r requirements.txt
cd ..
aws s3 cp s3://hep-adl-ethz/hep-parquet/ . --recursive --include "*.parquet"
cp -r ~/hep-iris-benchmark-jsoniq .
cd ~

# Set up docker
sudo service docker start
sudo usermod -a -G docker ec2-user
docker pull rumbledb/rumble:latest

# Remove the downloaded artifacts
rm -rf jdk-8u271-linux-x64.tar.gz spark-3.0.2-bin-hadoop2.7.tgz rumble

