# terraform setup

## general

Terraform is the infrastructure as a code tool for my project because:

- I would like to learn it
- it's generally used, eg. my knowledge can be useful with vmware, other clouds, kubernetes, etc.
- the proper way of working with infrastructure is through automation like terraform for infra, ansible for os level

This documentation doesn't include general terraform installation, only my specific settings like permissions and storing state file in s3 bucket.

## state file

TODO:

- create s3 bucket via cli, as admin user and block all public access

```bash
aws s3api create-bucket --bucket ${BUCKET_NAME} --region ${REGION} --create-bucket-configuration LocationConstraint=${REGION}
aws s3api put-public-access-block --bucket ${BUCKET_NAME} --public-access-block-configuration "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"
```

- necessary permissions for the s3 bucket, fill in the policy, replace variables with values

```bash
aws iam create-policy --policy-name ${PROJECT_NAME}_terraform_statefile --policy-document file://${GIT_REPO_ROOT}/${PROJECT_NAME}/policy/${PROJECT_NAME}_terraform_statefile.json --tags Key=project,Value=${PROJECT_NAME}
aws iam attach-role-policy --role-name ${PROJECT_NAME} --policy-arn arn:aws:iam::${AWS_ACCOUNT_ID}:policy/${PROJECT_NAME}_terraform_statefile
```

- configure terraform to store in s3

```text
terraform {
  backend "s3" {
    bucket = "${BUCKET_NAME}"
    key    = "statefile/${PROJECT_NAME}"
    region = "${REGION}"
  }
}
```

- dynamodb locking isn't implemented yet

## aws access

The project role is used to deploy environment via terraform which defined for the project in the iam documentation. This role is protected with multi factor authentication which doesn't supported by terraform.

The following steps are needed for deployment:

- ask for session token via mfa

```bash
aws sts get-session-token --duration-seconds 3600 --serial-number arn:aws:iam::${AWS_ACCOUNT_ID}:mfa/${AWS_USER} --profile ${AWS_USER} --token-code [token code from mfa]
```

- export the variables

```bash
export AWS_ACCESS_KEY_ID=[output of previous command]
export AWS_SECRET_ACCESS_KEY=[output of previous command]
export AWS_SESSION_TOKEN=[output of previous command]
```

- use the terraform commands eg. ```terraform plan```. The assume role is part of the terraform code

For easier export use the following command.

This will ask for the mfa code (without any text on the screen) then display the 3 export commands with the proper values. Simply copy-paste the export commands after.

```bash
read code && aws sts get-session-token --duration-seconds 900 --serial-number arn:aws:iam::${AWS_ACCOUNT_ID}:mfa/${AWS_USER} --profile ${AWS_USER} --token-code $code --output text | awk '{print "export AWS_ACCESS_KEY_ID=" $2 "\n" "export AWS_SECRET_ACCESS_KEY=" $4 "\n" "export AWS_SESSION_TOKEN=" $5}'
```

A better solution will be to set up external credentials process with a custom script, software. This is out of the scope of this documentation at the moment.
