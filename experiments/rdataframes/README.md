# Setup

1. Run the `deploy.sh` script to deploy an RDF VM in AWS 
2. Run the `upload.sh` script to fetch the relevant data into the RDF VM. Make sure to select only the data you plan to experiment on
4. Run `run_experiments.sh`; make sure to update the script such that only the queries you intend to execute are being executed

Note that when running experiments you will likely see `warning` messages stemming from comparisons stemming from the query. You can safely ignore those. 