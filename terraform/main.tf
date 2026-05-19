terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.92"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.0"
    }
  }

  required_version = ">= 1.2"

  backend "s3" {
    bucket  = "my-tf-state-jkm-sde-1"
    key     = "dev/terraform.tfstate"
    region  = "us-east-1"
    encrypt = true
  }
}

provider "aws" {
  region = var.aws_region
}

# ----------------------------------------
# S3 Bucket
# ----------------------------------------

resource "aws_s3_bucket" "input_bucket" {
  bucket_prefix = var.input_bucket

  tags = {
    Environment = var.environment
  }
}

# ----------------------------------------
# AMI
# ----------------------------------------

data "aws_ami" "debian" {
  most_recent = true
  owners      = ["136693071363"]

  filter {
    name   = "name"
    values = ["debian-12-amd64-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# ----------------------------------------
# IAM Role (EC2 -> S3 access)
# ----------------------------------------

resource "aws_iam_role" "ec2" {
  name = "ec2-s3-role-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "s3_access" {
  role = aws_iam_role.ec2.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "s3:GetObject",
        "s3:PutObject",
        "s3:DeleteObject",
        "s3:ListBucket"
      ]
      Resource = [
        aws_s3_bucket.input_bucket.arn,
        "${aws_s3_bucket.input_bucket.arn}/*"
      ]
    }]
  })
}

resource "aws_iam_instance_profile" "ec2" {
  name = "ec2-s3-profile-${var.environment}"
  role = aws_iam_role.ec2.name
}

# ----------------------------------------
# EC2 Instance
# ----------------------------------------

resource "aws_instance" "this" {
  ami                  = data.aws_ami.debian.id
  instance_type        = var.instance_type
  iam_instance_profile = aws_iam_instance_profile.ec2.name

  user_data = <<-EOF
    #!/bin/bash
    apt-get update -y
    apt-get install -y python3 python3-pip
    pip3 install boto3
  EOF

  tags = {
    Name        = "ec2-${var.environment}"
    Environment = var.environment
  }
}

# ----------------------------------------
# OIDC Provider
# ----------------------------------------

resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["9514f4ed3c841c96c43def0f0acbf177405ded12"]
}

# ----------------------------------------
# IAM Role for GitHub Actions
# ----------------------------------------

resource "aws_iam_role" "github_actions" {
  name = "github-actions"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Federated = aws_iam_openid_connect_provider.github.arn }
      Action    = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringLike = {
          "token.actions.githubusercontent.com:sub" = "repo:josephmachado/iac_cicd_de:*"
        }
      }
    }]
  })
}

resource "aws_iam_role_policy" "github_actions" {
  role = aws_iam_role.github_actions.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "ec2:*",
        "s3:*",
        "iam:*",
        "ssm:SendCommand",
        "ssm:GetCommandInvocation"
      ]
      Resource = "*"
    }]
  })
}

# ----------------------------------------
# Outputs
# ----------------------------------------

output "aws_role_arn" {
  value = aws_iam_role.github_actions.arn
}

resource "local_file" "outputs" {
  filename = "${path.module}/outputs.txt"
  content  = "aws_role_arn = ${aws_iam_role.github_actions.arn}\n"
}
