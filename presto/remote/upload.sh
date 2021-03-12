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

# Set up the table and the view
cat /data/queries/queries/common/functions.sql |
    docker exec -i docker-presto_presto_1 presto-cli \
        --server localhost:8080 \
        --catalog hive --schema default \
        --file /dev/stdin

for i in 1000 2000 4000 8000 16000 32000 64000 128000 256000 512000 1024000 2048000 4096000 8192000 16384000 32768000 65536000
do
	sed "s/{i}/${i}/g" /data/queries/scripts/make_db_native.sql | \
        docker exec -i docker-presto_presto_1 presto-cli \
            --server localhost:8080 \
            --catalog hive --schema default \
            --file /dev/stdin
done
