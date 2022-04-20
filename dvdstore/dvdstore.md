# DVD Store project documentation

## general information

This project is based on the Dell DVDStore application (https://github.com/dvdstore/ds3), it's purpose is to learn about AWS by installing the fictional company's web application like on premises then  migrate, rebuild it in a cloud aware way.

This project isn't planned to be AWS free tier compatible and tested in European regions (eu-north-1).

The documentation is using aws cli whenever it's possible and it's tested on Mac OS or Linux with bash shell. If the steps performed on different setup then the bash shell specific parts needs to be replaced.

The project is using the following tag whenever it's possible: Key=project,Value=dvdstore, as this is a learning project I'm not sure yet how will I use the tag.

## IAM setup

In the principle of least privilege the IAM setup is the following:

There is an administrator account (which isn't the root user) which only used to set up IAM permissions and related resources and there is a developer account which will interact with aws to build and manage the application. The permissions for the user are defined in a role and the user need to assume the necessary role to manage the application.

The elements of security concept are the following:

- admin user: this account is used to set up security policies in the aws account, the technical details of this user isn't part of this documentation but in general it have AdministratorAccess policy assigned. I will mention when something needed to do as an admin.
- application policy: this policy defines the necessary permissions to deploy the applicaton (like create ec2, rds instances)
- application role: this role associated with the application policy
- assumerole policy: this policy allows the associated users to assume the application role, this policy requires multi-factor authentication
- application group: the assumerole policy assigned to this group, the members can assume the application role
- learnaws user: this account represent the developer who deploy the application, it is a member of the application group and can receive the necessary permissions through the assume role mechanism

### create general account permissions

Do these steps as administrator user.

First step is to create the developer user and set up the self-management permissions for it.

'''set environment variables'''

These variables are used in the examples below, it safe to simply replace the example commands with the values also.

```bash
export AWS_ACCOUNT_ID="used aws account ID without dash characters"
export AWS_USER="name of the user who will be the developer"
export GIT_REPO_ROOT="the path to the root of the git repository in the file system"
```

'''create policy'''

This policy will give the user the permission to set up it's own mfa device and manage own credentials (like password, access key) after successful authentication with mfa.

Source documentation: <https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies_examples_aws_my-sec-creds-self-manage.html>

```bash
aws iam create-policy --policy-name iam-self_manage_mfa --policy-document file://$GIT_REPO_ROOT/dvdstore/policy/iam-self_manage_mfa.json --tags Key=project,Value=dvdstore
```

'''create group'''

Policies are assigned to groups and users are in the groups where they need permissions as best practice.

This group will include users which needs the self-management permissions.

```bash
aws iam create-group --group-name iam-self_management
```

'''attach policies'''

```bash

aws iam attach-group-policy --group-name iam-self_management --policy-arn arn:aws:iam::$AWS_ACCOUNT_ID:policy/iam-self_manage_mfa
```

'''create user'''

```bash
aws iam create-user --user-name $AWS_USER --tags Key=project,Value=dvdstore
```

'''add user to group'''

```bash
aws iam add-user-to-group --user-name $AWS_USER --group-name iam-self_management
```

'''set initial access key for user'''

Set initial access key for user, then hand it over him then he can set up mfa device for own account. With mfa the user can replace the access key, set up password, etc.

```bash
aws iam create-access-key --user-name $AWS_USER
```

### set up own account

Do these steps as developer user.

We suppose that the real person who uses the developer account have multiple aws users and use different profiles for these, not the default, for example:

~/.aws/config

```ini
[profile learn_aws]
region = eu-north-1
output = table
```

~/.aws/credentials

```ini
[learn_aws]
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
aws iam create-virtual-mfa-device --virtual-mfa-device-name $AWS_USER --outfile mfa.png --bootstrap-method QRCodePNG --tags Key=project,Value=dvdstore
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
aws iam create
```

Write the new access and secret key to the ~/.aws/credentials file.

TODO: provide proper commands

```bash
aws iam update-access-key --access-key-id ........ --status Inactive --user-name $AWS_USER
delete
```

Finally, unset the variables with the mfa access key, this will drop the self-management privileges and the user will be back to his own.

```bash
unset AWS_ACCESS_KEY_ID
unset AWS_SECRET_ACCESS_KEY
unset AWS_SESSION_TOKEN
```

### create project specific permissions

Do these steps as administrator user.

https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_create_for-user.html
https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_use_permissions-to-switch.html
https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_use_switch-role-cli.html

'''create group'''

```bash
aws iam create-group --group-name dvdstore
```

'''add user to group'''

```bash
aws iam add-user-to-group --user-name $AWS_USER --group-name dvdstore
```

'''create role'''

The group type doesn't have principal to define in policies, it's only possible to define users. The workaround is to allow everyone in the trust policy to assume role in general, but define a policy  below which will restrict the assume of the dvdstore role only to the members of the dvdstore group.

Edit the AWS_ACCOUNT_ID to the proper value in $git_root/policy/assume_role_with_mfa.json and assume_dvdstore_role.json

```bash
aws iam create-role --role-name dvdstore-role --assume-role-policy-document file://iam-assume_role_with_mfa.json --tags Key=project,Value=dvdstore
```

'''create assume-role policy for the role'''

```bash
aws iam create-policy --policy-name dvdstore-role-policy --policy-document file://iam-assume_dvdstore_role.json --tags Key=project,Value=dvdstore
aws iam attach-group-policy --group-name dvdstore --policy-arn arn:aws:iam::$AWS_ACCOUNT_ID:policy/dvdstore-role-policy
```

''TODO text'''

```bash
aws iam create-policy --policy-name dvdstore-management-policy --policy-document file://dvdstore_management.json --tags Key=project,Value=dvdstore
aws iam attach-role-policy --role-name dvdstore-role --policy-arn arn:aws:iam::$AWS_ACCOUNT_ID:policy/dvdstore-management-policy
```

'''TODO test'''

get mfa session tokens and set it as environment variables

```bash
aws sts get-session-token --duration-seconds 900 --serial-number arn:aws:iam::$AWS_ACCOUNT_ID:mfa/$AWS_USER --profile learn_aws --token-code 
export AWS_ACCESS_KEY_ID=...
export AWS_SECRET_ACCESS_KEY=...
export AWS_SESSION_TOKEN=...
```

switch to role, set the role session tokens as environment variables

```bash
aws sts assume-role --role-arn arn:aws:iam::$AWS_ACCOUNT_ID:role/dvdstore-role --role-session-name "test_dvdstore"
export AWS_ACCESS_KEY_ID=...
export AWS_SECRET_ACCESS_KEY=...
export AWS_SESSION_TOKEN=...
```

test the access then unset the role tokens

```bash
aws ec2 describe-tags --region eu-north-1
unset AWS_ACCESS_KEY_ID
unset AWS_SECRET_ACCESS_KEY
unset AWS_SESSION_TOKEN
```

profile assume will handle mfa:
https://docs.aws.amazon.com/cli/latest/topic/config-vars.html#using-aws-iam-roles

more complex switch with profiles and mfa, end goal:
https://www.redpill-linpro.com/techblog/2020/02/18/awscli.html