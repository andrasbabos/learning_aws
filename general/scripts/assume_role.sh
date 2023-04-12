source environment_variables.sh

role_output=$(aws sts assume-role --duration-seconds 3600 --profile ${PROJECT_NAME}_session --role-arn arn:aws:iam::${ACCOUNT_ID}:role/${PROJECT_NAME} --role-session-name "${PROJECT_NAME}_terraform" --output json)

aws configure set profile.${PROJECT_NAME}_terraform.aws_access_key_id `echo "${role_output}" | jq --raw-output ".Credentials[\"AccessKeyId\"]"`
aws configure set profile.${PROJECT_NAME}_terraform.aws_secret_access_key `echo "${role_output}" | jq --raw-output ".Credentials[\"SecretAccessKey\"]"`
aws configure set profile.${PROJECT_NAME}_terraform.aws_session_token `echo "${role_output}" | jq --raw-output ".Credentials[\"SessionToken\"]"`

echo "# role test with s3 ls:"
aws s3 ls --profile ${PROJECT_NAME}_terraform ${TERRAFORM_BUCKET_NAME}/statefile/${PROJECT_NAME}
