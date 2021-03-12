# Install prerequisites
sudo yum install -y git maven htop python3

# Get the presto client
wget https://repo1.maven.org/maven2/com/facebook/presto/presto-cli/0.248/presto-cli-0.248-executable.jar -O /data/presto.jar
chmod +x /data/presto.jar

# Install docker-compose
sudo curl -L "https://github.com/docker/compose/releases/download/1.28.5/docker-compose-Linux-x86_64" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
sudo ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose

# Install dependencies for query driver
cd /data/queries
python3 -m pip install --user -r requirements.txt

# Get the docker distribution
cd /data/docker-presto
docker-compose up -d

# Wait until Presto is ready
while ! /data/presto.jar --server localhost:8080 --catalog hive --schema default --execute "SELECT 42;"
do
    echo "Waiting for Presto to come up..."
    sleep 5s
done
