# terraform setup

## general

Terraform is the infrastructure as a code tool for my project because:

- I would like to learn it
- it's generally used, eg. my knowledge can be useful with vmware, other clouds, kubernetes, etc.
- the proper way of working with infrastructure is through automation like terraform for infra, ansible for os level

This documentation doesn't include general terraform installation, only my specific settings like permissions and storing state file in s3 bucket.

## awscli profile for terraform

Set up the minimal profile and credentials via aws cli, this will be used exclusively by terraform.

```bash
aws configure set profile.${PROJECT_NAME}_session.region ${REGION}
aws configure set profile.${PROJECT_NAME}_session.aws_access_key_id default_access_key
aws configure set profile.${PROJECT_NAME}_session.aws_secret_access_key default_secret_key

aws configure set profile.${PROJECT_NAME}_terraform.region ${REGION}
aws configure set profile.${PROJECT_NAME}_terraform.aws_access_key_id default_access_key
aws configure set profile.${PROJECT_NAME}_terraform.aws_secret_access_key default_secret_key
```

This will add entries like these to the users ~/.aws/config and credentials file.

config

```ini
[profile dvdstore_session]
region = eu-north-1

[profile dvdstore_terraform]
region = eu-north-1
```

credentials

```ini
[dvdstore_session]
aws_access_key_id = default_access_key
aws_secret_access_key = default_secret_key

[dvdstore_terraform]
aws_access_key_id = default_access_key
aws_secret_access_key = default_secret_key
```

## state file

TODO:

- create s3 bucket via cli, as admin user and block all public access

```bash
aws s3api create-bucket --bucket ${TERRAFORM_BUCKET_NAME} --region ${REGION} --create-bucket-configuration LocationConstraint=${REGION}
aws s3api put-public-access-block --bucket ${TERRAFORM_BUCKET_NAME} --public-access-block-configuration "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"
```

- necessary permissions for the s3 bucket, fill in the policy, replace variables with values

```bash
aws iam create-policy --policy-name ${PROJECT_NAME}_terraform_statefile --policy-document file://${GIT_REPO_ROOT}/${PROJECT_NAME}/policy/${PROJECT_NAME}_terraform_statefile.json --tags Key=project,Value=${PROJECT_NAME}
aws iam attach-role-policy --role-name ${PROJECT_NAME} --policy-arn arn:aws:iam::${ACCOUNT_ID}:policy/${PROJECT_NAME}_terraform_statefile
```

- configure terraform to store in s3

```text
terraform {
  backend "s3" {
    bucket = "${TERRAFORM_BUCKET_NAME}"
    key    = "statefile/${PROJECT_NAME}"
    region = "${REGION}"
    profile = ${PROJECT_NAME}_terraform
  }
}
```

- dynamodb locking isn't implemented yet

## access credentials

The project role is used to deploy environment via terraform which defined for the project in the iam documentation. This role is protected with multi factor authentication which doesn't supported by terraform.

Additionally the s3 backend bucket is available via iam policy after the role assumed but terraform tries to read the s3 bucket before assume and fails.

The current way of working for to the developer is the following:

- get session token
- set the token credentials in the config file for the ${PROJECT_NAME}_session profile
- assume role with the session profile
- set the role credentials in the config file for the ${PROJECT_NAME}_terraform profile
- use terraform commands with the ${PROJECT_NAME}_terraform profile provided in the terraform code

The detailed steps are the following:

- ask for session token

This will ask for the mfa code then set up the variables in the aws credentials file, the duration is 4 hours.

```bash
echo "enter mfa code:" && read code && session_output=$(aws sts get-session-token --duration-seconds 14400 --serial-number arn:aws:iam::${ACCOUNT_ID}:mfa/${USER_NAME} --profile ${USER_NAME} --token-code ${code} --output json)
```

```bash
aws configure set profile.${PROJECT_NAME}_session.aws_access_key_id `echo "${session_output}" | jq --raw-output ".Credentials[\"AccessKeyId\"]"`
aws configure set profile.${PROJECT_NAME}_session.aws_secret_access_key `echo "${session_output}" | jq --raw-output ".Credentials[\"SecretAccessKey\"]"`
aws configure set profile.${PROJECT_NAME}_session.aws_session_token `echo "${session_output}" | jq --raw-output ".Credentials[\"SessionToken\"]"`
```

- assume role

This will set up the variables. The AWS settings allow only one hour for the assume role, the parameter is set up there for the maximum value to remind me for it.

```bash
role_output=$(aws sts assume-role --duration-seconds 3600 --profile ${PROJECT_NAME}_session --role-arn arn:aws:iam::${ACCOUNT_ID}:role/${PROJECT_NAME} --role-session-name "${PROJECT_NAME}_terraform" --output json)
```

```bash
aws configure set profile.${PROJECT_NAME}_terraform.aws_access_key_id `echo "${role_output}" | jq --raw-output ".Credentials[\"AccessKeyId\"]"`
aws configure set profile.${PROJECT_NAME}_terraform.aws_secret_access_key `echo "${role_output}" | jq --raw-output ".Credentials[\"SecretAccessKey\"]"`
aws configure set profile.${PROJECT_NAME}_terraform.aws_session_token `echo "${role_output}" | jq --raw-output ".Credentials[\"SessionToken\"]"`
```

A better solution will be to set up external credentials process with a custom script, software. This is out of the scope of this documentation at the moment.

To test the credentials it's good to list the contents of the bucket which holds the statefile:

```bash
aws s3 ls --profile ${PROJECT_NAME}_terraform ${TERRAFORM_BUCKET_NAME}/statefile/${PROJECT_NAME}
```

I created two scripts get_token.sh and assume_role.sh which are in the general/scripts directory, these will do token and role part of the commands above. These are two separate scripts as the token needed every 4 hours but the role every hour.

## variables files

As best practice I separate code from data, the values for the variables are in different file.

The following files are used:

- variables.tf - declares the variables used in other .tf files
- terraform.tfvars - define values for variables. There is a terraform.tfvars.example file in the repository and the actual terraform.tfvars file is stored in a separate, private repository because I don't want to publicly expose my real variable values. In real situations the tfvars will be in this repository.

## provider settings

The provider block needs to set up with the proper values

- profile which is have the name ${PROJECT_NAME}_terraform in the config, credentials files
- region, if the region isn't us-east-1 then it needs to defined for sts operations

provider.tf

```terraform
provider "aws" {
  profile = "${PROJECT_NAME}_terraform"
  region  = "${REGION}"
}
```

The provider.tf.example is present in the repository the same way as terraform.tfvars.example

## backend settings

Configuration details of the s3 bucket which stores the state file

There are separate values from the provider as the state bucket is not necessarily is under the same account, in the same region.

backend.tf

```terraform
terraform {
  backend "s3" {
    profile = "${PROJECT_NAME}_terraform"
    region  = "${REGION}"
    bucket  = "${TERRAFORM_BUCKET_NAME}"
    key     = "statefile/${PROJECT_NAME}"
  }
}
```

The backend.tf.example is present in the repository the same way as terraform.tfvars.example
