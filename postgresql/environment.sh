# Get the data and start the docker image
cd /data && aws s3 cp s3://hep-adl-ethz/hep-parquet/original/ . --recursive --exclude="*" --include "Run2012B_SingleMu_*" && cd ~
docker run --name psql_deploy -v /data:/data -d dgraur/postgres_parquet:latest
wait 5

# Enable metrics in psql
docker exec psql_deploy cp /data/postgresql.conf /var/lib/postgresql/data/postgresql.conf
docker restart psql_deploy
wait 5

# Set up postgresql
docker exec psql_deploy python3 -m pip install -r /data/queries/requirements.txt
docker exec psql_deploy psql -U user user -c "create extension pg_stat_statements;"
docker exec psql_deploy psql -U user user -c "create extension parquet_fdw;"
docker exec psql_deploy psql -U user user -c "create server parquet_srv foreign data wrapper parquet_fdw;"
docker exec psql_deploy psql -U user user -c "create user mapping for user server parquet_srv options (user 'user');"

# Insert the data into psql
docker exec psql_deploy python3 /data/queries/scripts/create_single_table.py --create-types --foreign-table --data-size=1000
for i in {1..16}; do
	docker exec psql_deploy python3 /data/queries/scripts/create_single_table.py --foreign-table --data-size=$(( 1000 * 2 ** ${i} ))
done

