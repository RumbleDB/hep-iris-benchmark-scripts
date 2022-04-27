# PostgreSQL Query Execution Tutorial

In order to execute the HEP ADL benchmark queries with PostgreSQL one needs to follow the next steps:

1. Run the `./deploy.sh` script
1. Execute the `./run_experiments.sh` script (feel free to change what queries this runs; by default all PostgreSQL queries shown in the paper are executed)
1. The query execution data is dumped by default in `../experiments/postgres/experiment_yyyy-MM-dd-HH-mm-ss`. In this directory you will find:
    * The `instances.json` file with information on the VMs used for this experiment
    * A set of folders having the name `run_yyyy-MM-dd-HH-mm-ss.SSS` each containing detailed information on each of the queries executed during the experiment 
    * The `summary.jsonl` file which is obtained via the `postprocess_statistics.py` source. This aggregates all the individual query statistics into one `.jsonl` type file. 
1. Study or plot the above-mentioned  `summary.jsonl` file to see the query execution times
    * For the query execution time, one can scan the `total_exec_time` entries
    * For the number of read bytes, one can scan the `bytes_read` entry 
1. Terminate the cluster by running the `terminate.sh` script