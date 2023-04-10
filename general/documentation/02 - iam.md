# IAM setup

- [IAM setup](#iam-setup)
  - [create general account permissions](#create-general-account-permissions)
  - [set up developer account](#set-up-developer-account)
  - [create project specific permissions](#create-project-specific-permissions)
  - [create ssh key for project](#create-ssh-key-for-project)
  - [update project permissions](#update-project-permissions)
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

**create policy**

This policy will give the user the permission to set up it's own mfa device and manage own credentials (like password, access key) after successful authentication with mfa.

Source documentation: <https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies_examples_aws_my-sec-creds-self-manage.html>

```bash
aws iam create-policy --policy-name iam_self_management --policy-document file://${GIT_REPO_ROOT}/general/policy/iam_self_management.json --tags Key=project,Value=general
```

**create group**

Policies are assigned to groups and users are in the groups where they need permissions as best practice.

This group will include users which needs the self-management permissions.

```bash
aws iam create-group --group-name iam_self_management
```

**attach policies**

```bash

aws iam attach-group-policy --group-name iam_self_management --policy-arn arn:aws:iam::${ACCOUNT_ID}:policy/iam_self_management
```

**create user**

```bash
aws iam create-user --user-name ${USER_NAME} --tags Key=project,Value=general
```

**add user to group**

```bash
aws iam add-user-to-group --user-name ${USER_NAME} --group-name iam_self_management
```

set initial access key for user

Set initial access key for user, then hand it over him then he can set up mfa device for own account. With mfa the user can replace the access key, set up password, etc.

```bash
aws iam create-access-key --user-name ${USER_NAME}
```

## set up developer account

Do these steps as developer user.

We suppose that the real person who uses the developer account have multiple aws users and use different profiles for these, not the default, for example:

~/.aws/config

```ini
[profile ${USER_NAME}]
region = ${REGION}
output = table
```

~/.aws/credentials

```ini
[$USER_NAME]
aws_access_key_id = ........
aws_secret_access_key = ........
```

Here the access and secret key is the one provided by the administrator.

It's possible to define the profile as command line parameter but it's very error prone so we set up as environment variable.

```bash
export AWS_PROFILE=${USER_NAME}
aws iam get-user
```

create own virtual mfa device, this command will generate a picture file which whill contain the qr code. The user needs to import this into his own mfa application.

```bash
aws iam create-virtual-mfa-device --virtual-mfa-device-name ${USER_NAME} --outfile mfa.png --bootstrap-method QRCodePNG --tags Key=project,Value=general
```

Enable the mfa device, the 2 authentication code parameters needs to be the actual and following token code from the mfa application.

```bash
aws iam enable-mfa-device --user-name ${USER_NAME} --serial-number arn:aws:iam::${ACCOUNT_ID}:mfa/${USER_NAME} --authentication-code1 [actual code] --authentication-code2 [following code]
```

Get a valid session token with the new mfa device, the token code is from the mfa application.

```bash
aws sts get-session-token --duration-seconds 900 --serial-number arn:aws:iam::${ACCOUNT_ID}:mfa/${USER_NAME} --token-code [actual code]
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
aws iam create-access-key --user-name ${USER_NAME}
```

Write the new access and secret key to the ~/.aws/credentials file.

Set the original access key to inactive then delete it.

```bash
aws iam update-access-key --access-key-id ........ --status Inactive --user-name ${USER_NAME}
aws iam delete-access-key --access-key-id ........ --user-name ${USER_NAME}
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
aws iam create-group --group-name ${PROJECT_NAME}
```

add user to group

```bash
aws iam add-user-to-group --user-name ${USER_NAME} --group-name ${PROJECT_NAME}
```

**create role**

It's only possible to define users in policies, the group type doesn't have the required principal. The workaround is to allow everyone in the trust policy to assume role in general, but define a policy below which will restrict the assume of the PROJECT_NAME role only to the members of the PROJECT_NAME group.

Edit the ACCOUNT_ID to the proper value in ```GIT_REPO_ROOT/general/policy/assume_role_with_mfa.json``` and ```GIT_REPO_ROOT/PROJECT_NAME/policy/assume_PROJECT_NAME_role.json```

Allow every user to assume roles in general when they're authenticated with mfa.

Used documentation: <https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_create_for-user.html>

```bash
aws iam create-role --role-name ${PROJECT_NAME} --assume-role-policy-document file://${GIT_REPO_ROOT}/general/policy/assume_role_with_mfa.json --tags Key=project,Value=${PROJECT_NAME}
```

**create assume-role policy for the role**

This will allow the members of the group PROJECT_NAME to assume the role PROJECT_NAME.

Used documentation: <https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_use_permissions-to-switch.html>

```bash
aws iam create-policy --policy-name assume_${PROJECT_NAME}_role --policy-document file://${GIT_REPO_ROOT}/${PROJECT_NAME}/policy/assume_${PROJECT_NAME}_role.json --tags Key=project,Value=${PROJECT_NAME}
aws iam attach-group-policy --group-name ${PROJECT_NAME} --policy-arn arn:aws:iam::${ACCOUNT_ID}:policy/assume_${PROJECT_NAME}_role
```

**Define permissions and assign to role**

Define the permissions to manage the application in the PROJECT_NAME-management policy then attach this policy to the role PROJECT_NAME.

Alternatively the almost empty test policy can be used: ```file://${GIT_REPO_ROOT}/general/policy/project_management.json```, this defines minimal ec2 permissions to test the whole role process itself.

```bash
aws iam create-policy --policy-name ${PROJECT_NAME}_management --policy-document file://${GIT_REPO_ROOT}/${PROJECT_NAME}/policy/${PROJECT_NAME}_management.json --tags Key=project,Value=${PROJECT_NAME}
aws iam attach-role-policy --role-name ${PROJECT_NAME} --policy-arn arn:aws:iam::${ACCOUNT_ID}:policy/${PROJECT_NAME}_management
```

**test permissions**

get mfa session tokens and set it as environment variables

```bash
aws sts get-session-token --duration-seconds 900 --serial-number arn:aws:iam::${ACCOUNT_ID}:mfa/${USER_NAME} --profile ${USER_NAME} --token-code [token code from mfa]
export AWS_ACCESS_KEY_ID=...
export AWS_SECRET_ACCESS_KEY=...
export AWS_SESSION_TOKEN=...
```

switch to role, set the role session tokens as environment variables

```bash
aws sts assume-role --role-arn arn:aws:iam::${ACCOUNT_ID}:role/${PROJECT_NAME} --role-session-name "test_${PROJECT_NAME}"
export AWS_ACCESS_KEY_ID=...
export AWS_SECRET_ACCESS_KEY=...
export AWS_SESSION_TOKEN=...
```

test the access to additional permissions

```bash
aws ec2 describe-tags --region ${REGION}
```

unset the role tokens

```bash
unset AWS_ACCESS_KEY_ID
unset AWS_SECRET_ACCESS_KEY
unset AWS_SESSION_TOKEN
```

## create ssh key for project

Ssh key pair is needed for the ec2 instances, it is a security credential and it's also created outside of the project's terraform code.

This step needs to be run as an administrator user or as the developer user assuming the project role.

```bash
aws ec2 create-key-pair --key-name ${PROJECT_NAME}_deployment --region ${REGION} --profile ${PROJECT_NAME}_terraform
```

Save the private key part from the output and use it later as the ssh private key when needed.

The aws cli ouptut format will be one line string with multiple \n, new line characters, it needs to be saves like this:

```text
-----BEGIN RSA PRIVATE KEY-----
MIIEpAIBAAKCA.....
MIIEpAIBAAKCA.....
-----END RSA PRIVATE KEY-----
```

## update project permissions

To update a policy do the following steps:

list policies to get the policy-arn value

```bash
aws iam list-policies
```

```bash
aws iam create-policy-version --policy-document ile://${GIT_REPO_ROOT}/${PROJECT_NAME}/policy/${PROJECT_NAME}_management.json --policy-arn "arn:aws:iam::${ACCOUNT_ID}:policy/${PROJECT_NAME}_management" --set-as-default
```

There can be only five versions of a policy, so delete the old one.

```bash
aws iam create-policy-version  --policy-arn "arn:aws:iam::${ACCOUNT_ID}:policy/${PROJECT_NAME}_management" --version-id v1
```

## streamline the assume role process

**streamline with profile**

To streamline the assume role process do the following:

Edit config file and add the role as a profile with the following parameters:

~/.aws/config

```ini
[profile ${PROJECT_NAME}_role]
source_profile = ${USER_NAME}
region = ${REGION}
role_arn = arn:aws:iam::${ACCOUNT_ID}:role/${PROJECT_NAME}
mfa_serial = arn:aws:iam::${ACCOUNT_ID}:mfa/${USER_NAME}
```

Then the commands which are using the role needs the extra profile parameter:

```bash
aws ec2 describe-tags --profile ${PROJECT_NAME}_role
```

The command will ask for the mfa code and it will save the credentials in $HOME/.aws/cli/cache/some_file.json, subsequent executions will work with the mfa enabled token and the aws command will ask again for mfa code when the current credentials expired.

The aws sts get-session-token and aws sts assume roles won't be needed, but the --profile will be mandatory.

Used documentation:

- <https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_use_switch-role-cli.html>
- <https://docs.aws.amazon.com/cli/latest/topic/config-vars.html#using-aws-iam-roles>

**streamline without profile**

This will ask for the mfa code then display the 3 export commands with the proper values. Simply copy-paste the export commands after.

```bash
echo "enter mfa code:" && read code && aws sts get-session-token --duration-seconds 3600 --serial-number arn:aws:iam::${ACCOUNT_ID}:mfa/${USER_NAME} --profile ${USER_NAME} --token-code $code --output text | awk '{print "export AWS_ACCESS_KEY_ID=" $2 "\n" "export AWS_SECRET_ACCESS_KEY=" $4 "\n" "export AWS_SESSION_TOKEN=" $5}'
```

This is the second step to assume the role itself.

```bash
aws sts assume-role --role-arn arn:aws:iam::${ACCOUNT_ID}:role/${PROJECT_NAME} --role-session-name "test_${PROJECT_NAME}" --output text | awk '{print "export AWS_ACCESS_KEY_ID=" $2 "\n" "export AWS_SECRET_ACCESS_KEY=" $4 "\n" "export AWS_SESSION_TOKEN=" $5}'
```

Copy-paste the 3 export commands again.
