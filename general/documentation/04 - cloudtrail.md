# cloudtrail

## role of cloudtrail in this project

Cloudtrail can be used for long term auditing with proper setup, like creating the s3 bucket in different account setting up proper policies to reduce the possibility for the attacker to delete the trail or bucket settings, etc. This is a learning project first and this setup have lower priority so the documentation below is more of an example now than a proper setup.

## define, update permissions for management policy

Following the idea of least privilege the default management policy for a project only contains some basic read-only permissions and additional ones added when needed.

To figure these out it's possible to read documentation, add these based on "permission denied" error messages, but it makes more sense to add temporary admin permission to the role and log the successful api calls via cloudtrail.

To add temporary admin permission do the following:

```bash
aws iam attach-role-policy --role-name ${PROJECT_NAME} --policy-arn arn:aws:iam::aws:policy/AdministratorAccess
```

To delete after testing:

```bash
aws iam detach-role-policy --role-name ${PROJECT_NAME} --policy-arn arn:aws:iam::aws:policy/AdministratorAccess
```

It's important, new assume role is needed to re-read the changed policies!

## use cloudtrail ui for permissions

To quick check do the following:

- log in to the aws management ui
- open the cloudtrail service
- select the proper region
- on the left menu choose event history
- on top of the table set the filter to
  - username
  - name of the role

## define cloudtrail trail for long term auditing

Cloudtrail logs can be saved to s3 bucket for long term auditing, or programmatic processing. The first copy of management events are free.

Management events are like creating ec2 instances and data events like reading, writing objects in s3 buckets.

This example will create a management only trail which will collect all events in the given region. It's possible to fine-tune like add only various services or add only the terraform related bucket, dynamodb data operations, these aren't investigated yet (<https://docs.aws.amazon.com/awscloudtrail/latest/userguide/logging-management-events-with-cloudtrail.html>).

Create a bucket for logs:

```bash
aws s3api create-bucket --bucket ${CLOUDTRAIL_BUCKET_NAME} --region ${REGION} --create-bucket-configuration LocationConstraint=${REGION}
aws s3api put-public-access-block --bucket ${CLOUDTRAIL_BUCKET_NAME} --public-access-block-configuration "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"
```

create permission for cloudtrail to use the bucket, full json in the documentation:

<https://docs.aws.amazon.com/awscloudtrail/latest/userguide/create-s3-bucket-policy-for-cloudtrail.html>

Assign policy to bucket:

```bash
aws s3api put-bucket-policy --bucket ${CLOUDTRAIL_BUCKET_NAME} --policy file://policy.json
```

Create trail:

```bash
aws cloudtrail create-trail --name ${PROJECT_NAME}_management --s3-bucket-name ${CLOUDTRAIL_BUCKET_NAME}
```

Enable it  (it's also possible to stop):

```bash
aws cloudtrail start-logging --name ${PROJECT_NAME}_management
```

Get the status:

```bash
aws cloudtrail get-trail-status --name ${PROJECT_NAME}_management
```

The logging isn't immediate, it needs some minutes for the files to appear in the bucket.

## encrypted error message

When terraform got back error message like this:

```text
Error: error while describing instance (i-07...) attribute (instanceInitiatedShutdownBehavior): UnauthorizedOperation: You are not authorized to perform this operation. Encoded authorization failure message: teUZg3otoXVuN8v4LrRI...........
│ status code: 403, request id: 444.......
```

Then the message can be decoded with a user with necessary privileges.

```bash
aws sts decode-authorization-message --encoded-message teUZg
```

The output will be json formatted and contains the refused action.
