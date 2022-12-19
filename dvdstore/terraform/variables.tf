# backend

variable "backend_bucket" {
  type        = string
  description = "s3 bucket name where the tfstate file stored"
  nullable    = false
}

variable "backend_key" {
  type        = string
  description = "s3 path to the tfstate file"
  nullable    = false
}

variable "backend_profile" {
  type        = string
  description = "aws profile used by the backend code"
  nullable    = false
}

variable "backend_region" {
  type        = string
  description = "aws region where the backed bucket exists"
  nullable    = false
}

# provider

variable "provider_profile" {
  type        = string
  description = "aws profile used by the provider code"
  nullable    = false
}

variable "provider_region" {
  type        = string
  description = "aws region where the actual deployment took place"
  nullable    = false
}
