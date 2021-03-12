# Install docker-compose
sudo curl -L "https://github.com/docker/compose/releases/download/1.28.5/docker-compose-Linux-x86_64" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
sudo ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose

# Get the docker distribution
cd /data/docker-presto
docker-compose up -d

# Wait until Presto is ready
while ! docker exec -i docker-presto_presto_1 presto-cli --server localhost:8080 --catalog hive --schema default --execute "SELECT 42;"
do
    echo "Waiting for Presto to come up..."
    sleep 5s
done
