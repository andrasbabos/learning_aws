terraform {
  backend "s3" {
    profile = var.backend_profile
    region  = var.backend_region
    bucket  = var.backend_bucket
    key     = var.backend_key
  }
}
