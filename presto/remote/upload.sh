# Get the data
cd /data/docker-presto/data
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
docker exec docker-presto_namenode_1 hadoop fs -mkdir /dataset
docker exec docker-presto_namenode_1 hadoop fs -put /data/ /dataset/
docker exec docker-presto_namenode_1 hadoop fs -ls /dataset
