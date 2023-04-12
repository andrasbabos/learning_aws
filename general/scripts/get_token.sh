source environment_variables.sh

echo "enter mfa code:"
read code
session_output=$(aws sts get-session-token --duration-seconds 14400 --serial-number arn:aws:iam::${ACCOUNT_ID}:mfa/${USER_NAME} --profile ${USER_NAME} --token-code ${code} --output json)

aws configure set profile.${PROJECT_NAME}_session.aws_access_key_id `echo "${session_output}" | jq --raw-output ".Credentials[\"AccessKeyId\"]"`
aws configure set profile.${PROJECT_NAME}_session.aws_secret_access_key `echo "${session_output}" | jq --raw-output ".Credentials[\"SecretAccessKey\"]"`
aws configure set profile.${PROJECT_NAME}_session.aws_session_token `echo "${session_output}" | jq --raw-output ".Credentials[\"SessionToken\"]"`
