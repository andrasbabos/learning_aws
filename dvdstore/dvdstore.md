# DVD Store project documentation

## general information

TODO

- purpose, details of this project
- choosing region, not free account aware
- used files path in the example

## IAM setup

TODO

- explanation, i do these steps with an admin user
- describe the two security paths, the user rights are directly attached to groups, the project rights are available through assume role with mfa

The security concept is the following:

- admin user: this account is used to set up security policies in the aws account, the technical details of this user isn't part of this documentation but in general it have AdministratorAccess policy assigned. I will mention when something needed to do as an admin.
- application policy: this policy defines the necessary permissions to deploy the applicaton (like create ec2, rds instances)
- application role: this role associated with the application policy
- assumerole policy: this policy allows the associated users to assume the application role, this policy requires multi-factor authentication
- application group: the assumerole policy assigned to this group, the members can assume the application role
- learnaws user: this account represent the developer who deploy the application, it is a member of the application group and can receive the necessary permissions through the assume role mechanism

### create general account permissions

TODO general explanation about why they have password and access key

'''set environment variables'''

TODO explanation about this variable, it's visible on the webconsole

```bash
export AWS_ACCOUNT_ID="used aws account ID without dash characters"
export AWS_USER="name of the user who will be the developer"
```

'''create policy'''

TODO text, mfa, source: <https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies_examples_aws_my-sec-creds-self-manage.html>

```bash
aws iam create-policy --policy-name iam-self_manage_mfa --policy-document file://iam-self_manage_mfa.json --tags Key=project,Value=dvdstore
```

'''create group'''

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

TODO set initial access key for user, user can set up own mfa through cli

```bash
aws iam create-access-key --user-name $AWS_USER
```

hand over keys to user

### TODO meaningful text, set up new user account

TODO short info about profile

```bash
export AWS_PROFILE=$AWS_USER
aws iam get-user
```

create own virtual mfa device

```bash
aws iam create-virtual-mfa-device --virtual-mfa-device-name $AWS_USER --outfile mfa.png --bootstrap-method QRCodePNG --tags Key=project,Value=dvdstore
```

enable it

```bash
aws iam enable-mfa-device --user-name $AWS_USER --serial-number arn:aws:iam::$AWS_ACCOUNT_ID:mfa/$AWS_USER --authentication-code1 123456 --authentication-code2 789012
```

```bash
aws sts get-session-token --duration-seconds 900 --serial-number arn:aws:iam::$AWS_ACCOUNT_ID:mfa/$AWS_USER --token-code 123456
```

```bash
export AWS_ACCESS_KEY_ID=...
export AWS_SECRET_ACCESS_KEY=...
export AWS_SESSION_TOKEN=...
```

test access with mfa key

```bash
aws iam list-access-keys
```

aws iam create
aws iam update-access-key --access-key-id AKIAIOSFODNN7EXAMPLE --status Inactive --user-name Bob
delete

unset AWS_ACCESS_KEY_ID
unset AWS_SECRET_ACCESS_KEY
unset AWS_SESSION_TOKEN

### create project specific permissions

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