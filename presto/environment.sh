#!/usr/bin/env bash

# Change mounting points
sudo mkdir -p /var/lib/docker /data/docker /data/hadp
sudo mount --bind /data/docker /var/lib/docker 

# Install prerequisites
sudo yum -y update
sudo yum install -y git maven htop python3 docker

# Set up docker
sudo service docker start
sudo usermod -a -G docker ec2-user

# Get the presto client
cd /data
wget https://repo1.maven.org/maven2/com/facebook/presto/presto-cli/0.248/presto-cli-0.248-executable.jar
mv presto-cli-0.248-executable.jar presto.jar
chmod +x presto.jar

# Install docker-compose
sudo curl -L "https://github.com/docker/compose/releases/download/1.28.5/docker-compose-Linux-x86_64" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
sudo ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose

# TODO(Dan): Complete this step when the queries are public
# cd /data
# git clone <url>
cd /data/iris-hep-benchmark-presto
python3 -m pip install --user -r requirements.txt

# Get the docker distribution
cd /data
git clone https://github.com/DanGraur/docker-presto.git
cd docker-presto
sudo docker-compose up &> log.txt & 
sleep 300

# Get the data; note that we're in /data/docker-presto now
cd data 
aws s3 cp s3://hep-adl-ethz/hep-parquet/ . --recursive --include "*.parquet"
(
	cd native && \
	for i in 1000 2000 4000 8000 16000 32000 64000 128000; 
	do 
		mkdir Run2012B_SingleMu-${i}.parqueta && \
		mv Run2012B_SingleMu-${i}.parquet Run2012B_SingleMu-${i}.parqueta/ && \
		mv Run2012B_SingleMu-${i}.parqueta Run2012B_SingleMu-${i}.parquet
	done
)
# (cd original && for i in 1000 2000 4000 8000 16000 32000 64000 128000; do mv ${i} ${i}a && mkdir ${i} && mv ${i}a ${i} && mv ${i}/${i}a ${i}/${i}; done)

# Copy the data to HDFS
sudo docker exec -it docker-presto_namenode_1 hadoop fs -mkdir /dataset
sudo docker exec -it docker-presto_namenode_1 hadoop fs -put /data/ /dataset/
sudo docker exec -it docker-presto_namenode_1 hadoop fs -ls /dataset

# Set up the table and the view
/data/presto.jar --server localhost:8080 --catalog hive --schema default --file /data/iris-hep-benchmark-presto/queries/common/functions.sql

for i in 1000 2000 4000 8000 16000 32000 64000 128000 256000 512000 1024000 2048000 4096000 8192000 16384000 32768000 65536000
do
	sed "s/{i}/${i}/g" /data/iris-hep-benchmark-presto/scripts/make_db_native.sql | /data/presto.jar --server localhost:8080 --catalog hive --schema default --file /dev/stdin
done
