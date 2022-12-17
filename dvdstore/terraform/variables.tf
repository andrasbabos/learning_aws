# backend

variable "backend_bucket" {
  type        = string
  description = ""
  nullable    = false
}

variable "backend_key" {
  type        = string
  description = ""
  nullable    = false
}

variable "backend_profile" {
  type        = string
  description = ""
  nullable    = false
}

variable "backend_region" {
  type        = string
  description = ""
  nullable    = false
}

# provider

variable "provider_profile" {
  type        = string
  description = ""
  nullable    = false
}

variable "provider_region" {
  type        = string
  description = ""
  nullable    = false
}
