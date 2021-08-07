cd /data && aws s3 cp s3://hep-adl-ethz/hep-parquet/original/ . --recursive --exclude="*" --include "Run2012B_SingleMu_*"
docker run --name psql_deploy -v /data:/data:ro -d dgraur/postgres_parquet:latest
docker exec -it psql_deploy psql -U user 

# Set up postgresql
docker exec -it psql_deploy psql -U user user -c "create extension parquet_fdw;"
docker exec -it psql_deploy psql -U user user -c "create server parquet_srv foreign data wrapper parquet_fdw;"
docker exec -it psql_deploy psql -U user user -c "create user mapping for user server parquet_srv options (user 'user');"

# Insert the data into psql
docker exec -it psql_deploy python3 /data/scripts/create_single_table.py --create-types --foreign-table --data-size=1000
for i in {1..16}; do
	docker exec -it psql_deploy python3 /data/scripts/create_single_table --foreign-table --data-size=$(( 1000 * 2 ** ${i} ))
done

