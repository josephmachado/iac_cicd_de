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

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.ec2.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
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
    apt-get install -y python3 python3-pip git

    # install SSM agent
    wget https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/debian_amd64/amazon-ssm-agent.deb
    dpkg -i amazon-ssm-agent.deb
    systemctl enable amazon-ssm-agent
    systemctl start amazon-ssm-agent

    pip3 install boto3 --break-system-packages
  EOF

  tags = {
    Name        = "ec2-${var.environment}"
    Environment = var.environment
  }
}

# ----------------------------------------
# Outputs
# ----------------------------------------

output "instance_id" {
  value = aws_instance.this.id
}

output "bucket_name" {
  value = aws_s3_bucket.input_bucket.bucket
}

resource "local_file" "outputs" {
  filename = "${path.module}/outputs.txt"
  content  = <<-EOF
    instance_id  = ${aws_instance.this.id}
    bucket_name  = ${aws_s3_bucket.input_bucket.bucket}
  EOF
}
