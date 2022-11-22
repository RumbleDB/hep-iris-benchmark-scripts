# Setup

1. Manually create an Athena with the name `iris_hep_benchmark` following https://docs.aws.amazon.com/athena/latest/ug/creating-databases.html
2. Update `setup.sh` and `run_experiments.sh` with relevant values for `DATA_BUCKET_NAME` (where you uploaded the `parquet` data in S3), `STAGING_DIR`
3. Run `setup.sh`; this sets up the necessary data in Athena
4. Run `run_experiments.sh`; make sure to update the script such that only the queries you intend to execute are being executed

Note that for larger datsets (datasets with more than 1000 events), the queries will appear to be failing. This is not the case, as the queries are executed correctly in Athena. The failures stem from the python script which schedules the execution of the queries in Athena and then checks their output with reference results. As we only have reference results for datasets with 1k events, the checker will not find the reference and will fail. 