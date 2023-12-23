terraform {
  backend "s3" {
    profile = "${PROJECT_NAME}_terraform"
    region  = "${REGION}"
    bucket  = "${TERRAFORM_BUCKET_NAME}"
    key     = "statefile/${PROJECT_NAME}"
  }
}
