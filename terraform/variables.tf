variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "environment" {
  description = "Environment"
  type        = string
  default     = "dev"
}

variable "input_bucket" {
  type    = string
  default = "input-bucket"
}

variable "instance_type" {
  type    = string
  default = "t3.micro"
}
