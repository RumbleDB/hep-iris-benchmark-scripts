# Common

## AWS

1. [Install](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) and [configure](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-quickstart.html) the AWS CLI.
1. Set up an [SSH key for EC2](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/create-key-pairs.html) in your default region and make sure that that key is used by default for EC2 hosts. You may need to set the `IdentityFile` for `*.amazonaws.com` in your `~/.ssh/config` file.
1. Create an [S3 bucket](https://docs.aws.amazon.com/AmazonS3/latest/userguide/create-bucket-overview.html) in your default region for the input data.
1. Create an [IAM role](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/iam-roles-for-amazon-ec2.html#create-iam-role) and give it `AmazonS3ReadOnlyAccess`.
1. Paste the values from the above into [`config.sh`](config.sh.template).

## Local requirements

1. Install `jq`. For example:
   ```bash
   sudo apt install jq
   ```

