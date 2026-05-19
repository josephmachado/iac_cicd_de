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
    key     = "bootstrap/terraform.tfstate"
    region  = "us-east-1"
    encrypt = true
  }
}

provider "aws" {
  region = "us-east-1"
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
