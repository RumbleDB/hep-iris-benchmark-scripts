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

## Prerequisites

### Software installed locally

* The [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html).
* [Docker](https://docs.docker.com/engine/install/).
* Python 3 with `pip`. The systems using Python come with their own
  `requirements.txt`, which you probably want to install into dedicated
  [virtual environments](https://docs.python.org/3/library/venv.html).
* `jq`, `make`

### Local configuration

* Create a configuration file called `config.sh` in the
  [`experiments/common/`](common/) folder based on the
  [template](common/config.sh.template).

### AWS

#### `SSH_KEY_NAME`

The scripts assume that running `ssh some-ec2instance` works without user
intervention, so you should use your default SSH key in AWS. To do that, follow
[this guide](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/create-key-pairs.html#how-to-generate-your-own-key-and-import-it-to-aws).
The name that you choose during the key import is the one you need to store in
`SSH_KEY_NAME`.

#### `INSTANCE_PROFILE`

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

## Running experiments

### Typical experiment workflow

The flow for running the experiments is roughly the following:

1. Follow the setup procedure of each system as explained in the respective
   subfolder.
1. For self-managed systems, start the resources on AWS EC2 using `deploy.sh` and set up or upload the data on these resources using `upload.sh` of the respective system.
1. Run queries in one of the following ways:
   * Run individual queries using the `test_queries.py` script or (similar). The `deploy.sh` of the self-managed systems opens a tunnel to the deployed EC2 instances, such that you can use the local script with the cloud resources.
   * Modify and run `run_experiments.sh` to run a batch of queries and trace its results.
1. Terminate the deployed resources with `terminate.sh`.
1. Run `make -f path/to/common/make.mk -C results/results_date-of-experiment/` to parse the trace files and produce `result.json` with the statistics of all runs.

### Running different VM sizes

Self-deployed systems are evaluated in the paper by running the ADL benchmark
queries at a fixed scale factor for the data, while sweeping the VM size. For
these experiments, we chose SF1. We do not provide scripts for this, as such an
experiment can be expressed with a one-line bash command. We do provide an
example of such a command line below:

```bash
for x in 16x 12x 8x 4x 2x x ""; do ./deploy.sh 2 m5d.${x}large && ./upload.sh && ./run_experiments.sh; ./terminate.sh; done
```

Some systems, such as `postgresql` or `rumble` and `rumble-emr`, do not posses
or require an `upload.sh` script. Also note that some `run_experiments.sh`
scripts might feature different parameters that one can use to change the
dynamics of the experiments.

You should note that you should fix the scale of the data when doing the
experiment (otherwise the experiment will sweep both through the different scale
factors for the data and the different VM sizes). To do so, make sure to change
the setup at the end of the `run_experiments.sh` scripts in order to schedule
only the intended scale factor. For instance, the following snippet will ensure
only SF1 is being executed (which is the scale we used for the sweep experiments
in our paper):

```
...
NUM_EVENTS=($(for l in {16..16}; do echo $((2**$l*1000)); done))
QUERY_IDS=($(for q in 1 2 3 4 5 6-1 6-2 7 8; do echo query-$q; done))
run_many NUM_EVENTS QUERY_IDS no
...
```

Note that there might be different patterns for the query names depending on the
system.

## Mentions

Note that, for the RumbleDB experiments, we employed the
[`rumble-emr`](rumble-emr/) scripts and not the
[`obsolete_rumble`](obsolete_rumble/) scripts. We include the latter for
reference, but they serve not purpose for evaluation.
