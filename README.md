# Benchmark Scripts for *Evaluating Query Languages and Systems for High-Energy Physics Data*

[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.5569049.svg)](https://doi.org/10.5281/zenodo.5569049)

This repository contains benchmarks scripts for running the implementations of High-energy Physics (HEP) analysis queries from the [IRIS HEP benchmark](https://github.com/iris-hep/adl-benchmarks-index) for various general-purpose query processing systems. The results have been published in the following paper:

Dan Graur, Ingo Müller, Mason Proffitt, Ghislain Fourny, Gordon T. Watts, Gustavo Alonso.
*Evaluating Query Languages and Systems for High-Energy Physics Data.*
In: PVLDB 15(2), 2022.
DOI: [10.14778/3489496.3489498](https://doi.org/10.14778/3489496.3489498).

Please cite both, the paper and the software, when citing in academic contexts.

## Structure of this repository

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
```

## Running experiments

### Prerequisites

Before starting, the AWS CLI tool needs to be installed locally. Please follow [these instructions](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) in order to install the tool. 

Make sure to create a configuration file called `config.sh` in the `common/` folder. The file should have the following structure:

```
#!/usr/bin/env bash
SSH_KEY_NAME="<YOUR_AWS_KEY_NAME>"
INSTANCE_PROFILE="<YOUR_PREFERRED_ROLE>"
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
