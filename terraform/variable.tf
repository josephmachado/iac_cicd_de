variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-2"
}

# Input bucket variable name
variable "input_bucket" {
  description = "Bucket for input data"
  type        = string
  default     = "inputbucket"
}

# Environment
variable "environment" {
  description = "Environment"
  type        = string
  default     = "dev"
}


# Backend bucket variable name
variable "backend_bucket" {
  description = "Bucket for storing state"
  type        = string
  default     = "my-tf-state-jkm-sde-1"
}

