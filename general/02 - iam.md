# IAM setup

- [IAM setup](#iam-setup)
  - [create general account permissions](#create-general-account-permissions)
  - [set up developer account](#set-up-developer-account)
  - [create project specific permissions](#create-project-specific-permissions)
  - [update project permissions](#update-project-permissions)
  - [full example for copy-paste](#full-example-for-copy-paste)
  - [streamline the assume role process](#streamline-the-assume-role-process)

In the principle of least privilege the IAM setup is the following:

There is an administrator account (which isn't the root user) it is only used to set up IAM permissions and related resources and there is a developer account which will interact with aws to build and manage the application. The permissions for the user are defined in a role and the user need to assume the necessary role to manage the application.

The elements of security concept are the following:

- admin user: this account is used to set up security policies in the aws account, the technical details of this user isn't part of this documentation but in general it have AdministratorAccess policy assigned. I will mention when something needed to do as an admin.
- application policy: this policy defines the necessary permissions to deploy the applicaton (like create ec2, rds instances)
- application role: this role associated with the application policy
- assumerole policy: this policy allows the associated users to assume the application role, this policy requires multi-factor authentication
- application group: the assumerole policy assigned to this group, the members can assume the application role
- learnaws user: this account represent the developer who deploy the application, it is a member of the application group and can receive the necessary permissions through the assume role mechanism

## create general account permissions

Do these steps as administrator user.

First step is to create the developer user and set up the self-management permissions for it.

set environment variables

These variables are used in the examples below, it safe to simply replace the example commands with the values also.

```bash
export AWS_ACCOUNT_ID="used aws account ID without dash characters"
export AWS_USER="name of the user who will be the developer"
export GIT_REPO_ROOT="the path to the root of the git repository in the file system"
export PROJECT_NAME="name of the actual project eg. dvdstore" 
```

create policy

This policy will give the user the permission to set up it's own mfa device and manage own credentials (like password, access key) after successful authentication with mfa.

Source documentation: <https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies_examples_aws_my-sec-creds-self-manage.html>

```bash
aws iam create-policy --policy-name iam-self_manage_mfa --policy-document file://$GIT_REPO_ROOT/general/policy/iam-self_manage_mfa.json --tags Key=project,Value=general
```

create group

Policies are assigned to groups and users are in the groups where they need permissions as best practice.

This group will include users which needs the self-management permissions.

```bash
aws iam create-group --group-name iam-self_management
```

attach policies

```bash

aws iam attach-group-policy --group-name iam-self_management --policy-arn arn:aws:iam::$AWS_ACCOUNT_ID:policy/iam-self_manage_mfa
```

create user

```bash
aws iam create-user --user-name $AWS_USER --tags Key=project,Value=general
```

add user to group

```bash
aws iam add-user-to-group --user-name $AWS_USER --group-name iam-self_management
```

set initial access key for user

Set initial access key for user, then hand it over him then he can set up mfa device for own account. With mfa the user can replace the access key, set up password, etc.

```bash
aws iam create-access-key --user-name $AWS_USER
```

## set up developer account

Do these steps as developer user.

We suppose that the real person who uses the developer account have multiple aws users and use different profiles for these, not the default, for example:

~/.aws/config

```ini
[profile $AWS_USER]
region = eu-north-1
output = table
```

~/.aws/credentials

```ini
[$AWS_USER]
aws_access_key_id = ........
aws_secret_access_key = ........
```

Here the access and secret key is the one provided by the administrator.

It's possible to define the profile as command line parameter but it's very error prone so we set up as environment variable.

```bash
export AWS_PROFILE=$AWS_USER
aws iam get-user
```

create own virtual mfa device, this command will generate a picture file which whill contain the qr code. The user needs to import this into his own mfa application.

```bash
aws iam create-virtual-mfa-device --virtual-mfa-device-name $AWS_USER --outfile mfa.png --bootstrap-method QRCodePNG --tags Key=project,Value=general
```

Enable the mfa device, the 2 authentication code parameters needs to be the actual and following token code from the mfa application.

```bash
aws iam enable-mfa-device --user-name $AWS_USER --serial-number arn:aws:iam::$AWS_ACCOUNT_ID:mfa/$AWS_USER --authentication-code1 123456 --authentication-code2 789012
```

Get a valid session token with the new mfa device, the token code is from the mfa application.

```bash
aws sts get-session-token --duration-seconds 900 --serial-number arn:aws:iam::$AWS_ACCOUNT_ID:mfa/$AWS_USER --token-code 123456
```

This will output the new access, secret key and session token which are mfa enabled and allows to use the self-management permissions.

Export the values, these will take precedence over the defined values in the profile.

```bash
export AWS_ACCESS_KEY_ID=...
export AWS_SECRET_ACCESS_KEY=...
export AWS_SESSION_TOKEN=...
```

Test access with listing own access keys.

```bash
aws iam list-access-keys
```

Create a new access key which will known only by his owner, and delete the original which provided by the administrator.

```bash
aws iam create-access-key --user-name $AWS_USER
```

Write the new access and secret key to the ~/.aws/credentials file.

Set the original access key to inactive then delete it.

```bash
aws iam update-access-key --access-key-id ........ --status Inactive --user-name $AWS_USER
aws iam delete-access-key --access-key-id ........ --user-name $AWS_USER
```

Finally, unset the variables with the mfa access key, this will drop the self-management privileges and the user will be back to his own.

```bash
unset AWS_ACCESS_KEY_ID
unset AWS_SECRET_ACCESS_KEY
unset AWS_SESSION_TOKEN
```

## create project specific permissions

Do these steps as administrator user.

The project specific permissions are associated with a role, the developer user needs to assume this role with mfa to be able to manage the application and his permissions to assume the role is coming from his group membership.

create group

```bash
aws iam create-group --group-name $PROJECT_NAME
```

add user to group

```bash
aws iam add-user-to-group --user-name $AWS_USER --group-name $PROJECT_NAME
```

create role

It's only possible to define users in policies, the group type doesn't have the required principal. The workaround is to allow everyone in the trust policy to assume role in general, but define a policy below which will restrict the assume of the $PROJECT_NAME role only to the members of the $PROJECT_NAME group.

Edit the AWS_ACCOUNT_ID to the proper value in $GIT_REPO_ROOT/$PROJECT_NAME/policy/assume_role_with_mfa.json and assume_$PROJECT_NAME_role.json

Allow every user to assume roles in general when they're authenticated with mfa.

Used documentation: <https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_create_for-user.html>

```bash
aws iam create-role --role-name $PROJECT_NAME-role --assume-role-policy-document file://iam-assume_role_with_mfa.json --tags Key=project,Value=$PROJECT_NAME
```

create assume-role policy for the role

This will allow the members of the group $PROJECT_NAME to assume the role $PROJECT_NAME-role.

Used documentation: <https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_use_permissions-to-switch.html>

```bash
aws iam create-policy --policy-name $PROJECT_NAME-role-policy --policy-document file://iam-assume_$PROJECT_NAME_role.json --tags Key=project,Value=$PROJECT_NAME
aws iam attach-group-policy --group-name $PROJECT_NAME --policy-arn arn:aws:iam::$AWS_ACCOUNT_ID:policy/$PROJECT_NAME-role-policy
```

Define permissions and assing to role

Define the permissions to manage the application in the $PROJECT_NAME-management-policy policy then attach this policy to the role $PROJECT_NAME-role.

```bash
aws iam create-policy --policy-name $PROJECT_NAME-management-policy --policy-document file://$PROJECT_NAME_management.json --tags Key=project,Value=$PROJECT_NAME
aws iam attach-role-policy --role-name $PROJECT_NAME-role --policy-arn arn:aws:iam::$AWS_ACCOUNT_ID:policy/$PROJECT_NAME-management-policy
```

test permissions

get mfa session tokens and set it as environment variables

```bash
aws sts get-session-token --duration-seconds 900 --serial-number arn:aws:iam::$AWS_ACCOUNT_ID:mfa/$AWS_USER --profile $AWS_USER --token-code 
export AWS_ACCESS_KEY_ID=...
export AWS_SECRET_ACCESS_KEY=...
export AWS_SESSION_TOKEN=...
```

switch to role, set the role session tokens as environment variables

```bash
aws sts assume-role --role-arn arn:aws:iam::$AWS_ACCOUNT_ID:role/$PROJECT_NAME-role --role-session-name "test_$PROJECT_NAME"
export AWS_ACCESS_KEY_ID=...
export AWS_SECRET_ACCESS_KEY=...
export AWS_SESSION_TOKEN=...
```

test the access to additional permissions

```bash
aws ec2 describe-tags --region eu-north-1
```

unset the role tokens

```bash
unset AWS_ACCESS_KEY_ID
unset AWS_SECRET_ACCESS_KEY
unset AWS_SESSION_TOKEN
```

## update project permissions

To update a policy do the following steps:

list policies to get the policy-arn value

```bash
aws iam list-policies
```

```bash
aws iam create-policy-version --policy-document file://terraform_management.json --policy-arn "arn:aws:iam::$AWS_ACCOUNT_ID:policy/$PROJECT_NAME_management-policy" --set-as-default
```

There can be only five versions of a policy, so delete the old one.

aws iam create-policy-version  --policy-arn "arn:aws:iam::$AWS_ACCOUNT_ID:policy/$PROJECT_NAME_management-policy" --version-id v1

## full example for copy-paste

This is a full example for easier copy-paste, the used PROJECT_NAME name is terraform in the json files.

```bash
aws iam create-group --group-name $PROJECT_NAME
aws iam add-user-to-group --user-name learn_aws --group-name terraform

aws iam create-role --role-name $PROJECT_NAME-role --assume-role-policy-document file://iam-assume_role_with_mfa.json --tags Key=project,Value=$PROJECT_NAME

aws iam create-policy --policy-name $PROJECT_NAME-role-policy --policy-document file://iam-assume_$PROJECT_NAME_role.json --tags Key=project,Value=$PROJECT_NAME
aws iam attach-group-policy --group-name $PROJECT_NAME --policy-arn arn:aws:iam::$AWS_ACCOUNT_ID:policy/$PROJECT_NAME-role-policy

aws iam create-policy --policy-name $PROJECT_NAME-management-policy --policy-document file://$PROJECT_NAME_management.json --tags Key=project,Value=$PROJECT_NAME
aws iam attach-role-policy --role-name $PROJECT_NAME-role --policy-arn arn:aws:iam::$AWS_ACCOUNT_ID:policy/$PROJECT_NAME-management-policy
```

## streamline the assume role process

To streamline the assume role process do the following:

Edit config file and add the role as a profile with the following parameters:

~/.aws/config

```ini
[profile $PROJECT_NAME_role]
source_profile = $AWS_USER
role_arn = arn:aws:iam::$AWS_ACCOUNT_ID:role/$PROJECT_NAME-role
mfa_serial = arn:aws:iam::$AWS_ACCOUNT_ID:mfa/$AWS_USER
```

Then the commands which are using the role needs the extra profile parameter:

```bash
aws ec2 describe-tags --region eu-north-1 --profile $PROJECT_NAME_role
```

The command will ask for the mfa code and it will save the credentials in $HOME/.aws/cli/cache/some_file.json, subsequent executions will work with the mfa enabled token and the aws command will ask again for mfa code when the current credentials expired.

The aws sts get-session-token and aws sts assume roles won't be needed, but the --profile will be mandatory.

Used documentation:

- <https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_use_switch-role-cli.html>
- <https://docs.aws.amazon.com/cli/latest/topic/config-vars.html#using-aws-iam-roles>
