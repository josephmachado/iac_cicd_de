#!/bin/bash

USERNAME=josephmachado

# destroy sandbox
terraform -chdir=terraform init -reconfigure -backend-config="key=sandbox/$USERNAME/terraform.tfstate"
terraform -chdir=terraform destroy -auto-approve -var-file="envs/sandbox.tfvars" -var="environment=sandbox-$USERNAME"

# destroy dev
terraform -chdir=terraform init -reconfigure -backend-config="key=dev/terraform.tfstate"
terraform -chdir=terraform destroy -auto-approve -var-file="envs/dev.tfvars"

# destroy prod
terraform -chdir=terraform init -reconfigure -backend-config="key=prod/terraform.tfstate"
terraform -chdir=terraform destroy -auto-approve -var-file="envs/prod.tfvars"

# destroy bootstrap last
terraform -chdir=terraform/bootstrap init -reconfigure
terraform -chdir=terraform/bootstrap destroy -auto-approve
