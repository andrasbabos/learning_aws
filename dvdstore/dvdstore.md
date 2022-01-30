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

'''set environment variable'''

TODO explanation about this variable, it's visible on the webconsole

```bash
export AWS_ACCOUNT_ID="used aws account ID without dash characters"
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
aws iam create-user --user-name learn_aws --tags Key=project,Value=dvdstore
```

'''add user to group'''

```bash
aws iam add-user-to-group --user-name learn_aws --group-name iam-self_management
```

TODO set initial access key for user, user can set up own mfa through cli then rotate initial ak, set password

### create project specific permissions
