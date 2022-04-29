# Experiments

This folder contains the scripts for running the experiments.

## Structure of this folder

Each system in the comparison has its own directory, all with a similar structure. In particular, they import the actual query implementations from dedicated repositories (so be sure to `git clone --recursive ...`).

```
athena/
    queries/  # git submodule with query implementation
        ...
    parse.mk
    run_experiments.sh
    summarize_run.py
    ...
bigquery/
    ...
...
common/
    ...
query-analysis/
    ...
```

## Running experiments

### Prerequisites

Before starting, the AWS CLI tool needs to be installed locally. Please follow [these instructions](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) in order to install the tool. 

Make sure to create a configuration file called `config.sh` in the `experiments/common/` folder. We provide a template in `experiments/common/config.sh.template` that demonstrates the required structure of this file:

```
#!/usr/bin/env bash

# AWS specific values
SSH_KEY_NAME=""  # The name of the AWS key used to access S3 and EC2 
INSTANCE_PROFILE="<YOUR_PREFERRED_ROLE>"  # Identifies an IAM to pass to created EC2 instances 

S3_REGION=""  # The S3 region; e.g. "eu-central-1"
S3_INPUT_BUCKET=""  # The S3 bucket name where datasets are stored without the 's3://' prefix; e.g. "my-new-bucket"
S3_INPUT_PATH=s3://${S3_INPUT_BUCKET}/  # The full path within the bucket where the data is stored; e.g. s3://my-new-bucket/path/to/folder

# GCP specific values
GS_REGION=""  # The GCS region; e.g. "europe-west4-a"
GS_INPUT_BUCKET=""  # The GCS bucket name where datasets are stored without the 'gs://' prefix; e.g. "my-new-bucket"
GS_INPUT_PATH=gs://${GS_INPUT_BUCKET}/  # The full path within the bucket where the data is stored; e.g. gs://my-new-bucket/path/to/folder
```

The value of `SSH_KEY_NAME` should be filled in with the name of a Key Pair from AWS. The deployed cluster will require that key when being accessed via `ssh`. We highly recommend you use your default ssh key in AWS, as this will save a lot of effort when using our scripts (our scripts employ the default system ssh key when `ssh`-ing into AWS VMs). To import your default ssh key into AWS, follow these steps:

1. Locate your default ssh key (this is usually in `~/.ssh/`)
1. Open the default key's `.pub` file and copy its contents to the clipboard
1. In the `AWS Console`, go to the `EC2 Dashboard`, and click on the `Key Pairs` button
1. In the new window, there will be an `Actions` button in the top right corner. Click on this button and select the `Import key pair` option.
1. Provide a name for your key, and paste the contents of your clipboard into the big text box on this page (alternatively, you can upload the `.pub` file directly via the `Browse` option).
1. Finalize the process by clicking the `Import key pair` button at the bottom of the page. 

Alternatively, you can use a different key, but this will require that you modify the scripts where remote access is used such that the `-i` option is used to point to the relevant identity file. 

As an example, for `INSTANCE_PROFILE`, we created a role that affects the `AmazonElasticMapReduceforEC2Role` policy and has the following configuration. We then used the name of this role as the value of `INSTANCE_PROFILE`. 

```
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Resource": "*",
            "Action": [
                "cloudwatch:*",
                "dynamodb:*",
                "ec2:Describe*",
                "elasticmapreduce:Describe*",
                "elasticmapreduce:ListBootstrapActions",
                "elasticmapreduce:ListClusters",
                "elasticmapreduce:ListInstanceGroups",
                "elasticmapreduce:ListInstances",
                "elasticmapreduce:ListSteps",
                "kinesis:CreateStream",
                "kinesis:DeleteStream",
                "kinesis:DescribeStream",
                "kinesis:GetRecords",
                "kinesis:GetShardIterator",
                "kinesis:MergeShards",
                "kinesis:PutRecord",
                "kinesis:SplitShard",
                "rds:Describe*",
                "s3:*",
                "sdb:*",
                "sns:*",
                "sqs:*",
                "glue:CreateDatabase",
                "glue:UpdateDatabase",
                "glue:DeleteDatabase",
                "glue:GetDatabase",
                "glue:GetDatabases",
                "glue:CreateTable",
                "glue:UpdateTable",
                "glue:DeleteTable",
                "glue:GetTable",
                "glue:GetTables",
                "glue:GetTableVersions",
                "glue:CreatePartition",
                "glue:BatchCreatePartition",
                "glue:UpdatePartition",
                "glue:DeletePartition",
                "glue:BatchDeletePartition",
                "glue:GetPartition",
                "glue:GetPartitions",
                "glue:BatchGetPartition",
                "glue:CreateUserDefinedFunction",
                "glue:UpdateUserDefinedFunction",
                "glue:DeleteUserDefinedFunction",
                "glue:GetUserDefinedFunction",
                "glue:GetUserDefinedFunctions"
            ]
        }
    ]
}
```

### Experiment Workflow

The flow for running the experiments is roughly the following:

1. Follow the setup procedure of each system as explained in the respective git repositories. In particular, convert and upload the benchmark data where required.
1. For self-managed systems, start the resources on AWS EC2 using `deploy.sh` and set up or upload the data on these resources using `upload.sh` of the respective system.
1. Run queries in one of the following ways:
   * Run individual queries using the `test_queries.py` script or (similar). The `deploy.sh` of the self-managed systems opens a tunnel to the deployed EC2 instances, such that you can use the local script with the cloud resources.
   * Modify and run `run_experiments.sh` to run a batch of queries and trace its results.
1. Terminate the deployed resources with `terminate.sh`.
1. Run `make -f path/to/common/make.mk -C results/results_date-of-experiment/` to parse the trace files and produce `result.json` with the statistics of all runs.

### Running Different VM Sizes Sweeps

Self-deployed systems are evaluated in the paper by running the ADL benchmark queries at a fixed scale factor for the data, while sweeping the VM size. For these experiments we chose SF1. We do not provide scripts for this, as such an experiment can be expressed with a one-line bash command. We do provide an example of such a command line below:

```
for x in 16x 12x 8x 4x 2x x ""; do ./deploy.sh 2 m5d.${x}large && ./upload.sh && ./run_experiments.sh; ./terminate.sh; done
```  

Some systems, such as `postgresql` or `rumble` and `rumble-emr` do not posses or require an `upload.sh` script. Also note that some `run_experiments.sh` scripts might feature different parameters that one can use to change the dynamics of the experiments.

You should note that you should fix the scale of the data when doing the experiment (otherwise the experiment will sweep both through the different scale factors for the data and the different VM sizes). To do so, make sure to change the setup at the end of the `run_experiments.sh` scripts in order to schedule only the intended scale factor. For instance, the following snippet will ensure only SF1 is being executed (which is the scale we used for the sweep experiments in our paper):  

```
...
NUM_EVENTS=($(for l in {16..16}; do echo $((2**$l*1000)); done))
QUERY_IDS=($(for q in 1 2 3 4 5 6-1 6-2 7 8; do echo query-$q; done))
run_many NUM_EVENTS QUERY_IDS no
...
```

Note that there might be different patterns for the query names depending on the system. 

## Mentions

Note that for the RumbleDB experiments we employed the `experiments/rumble-emr` scripts, and not the `experiments/obsolete_rumble` scripts. We include the latter for reference, but they serve not purpose for evaluation. 
