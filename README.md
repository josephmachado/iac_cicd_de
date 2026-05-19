

1. Create an aws account https://signin.aws.amazon.com/signup?request_type=register
2. Install Terraform https://developer.hashicorp.com/terraform/install#darwin
3. Verify terraform is installed by running `terraform -help` on your terminal
4. Install AWS CLI with https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html
5. Log into AWS CLI with https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-sign-in.html#cli-configure-sign-in-login-command 

Create S3 bucket with terraform 

https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket

cd terraform
Format tf files with `terraform fmt`
Init with `terraform init`
validate config with `terraform validate`

create iam user 
get access key and secret for that users
create ~/.aws/credentials file 
with 

```bash
[default]
aws_access_key_id = YOUR_ACCESS_KEY
aws_secret_access_key = YOUR_SECRET_KEY
```

create s3 full access policy for the iam user 

run `terraform plan` 
To see what tf plans to add 

run `terraform apply`

run `aws s3 ls`

you will see something like 

```
 aws s3 ls                                       
2026-05-18 17:27:28 inputbucket20260518212646535400000001
```
See state of the infrastructure at ./terraform/terraform.tfstate

let's tear down the infra with 

```bash 
terraform destroy
```

now `aws s3 ls` will be empty


```bash 
# Create the bucket (replace with a unique name, S3 buckets are globally unique)
aws s3api create-bucket \
  --bucket my-tf-state-jkm-sde-1 \
  --region us-east-1

# Enable versioning
aws s3api put-bucket-versioning \
  --bucket my-tf-state-jkm-sde-1 \
  --versioning-configuration Status=Enabled

# Block public access
aws s3api put-public-access-block \
  --bucket my-tf-state-jkm-sde-1 \
  --public-access-block-configuration "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"

# Enable encryption
aws s3api put-bucket-encryption \
  --bucket my-tf-state-jkm-sde-1 \
  --server-side-encryption-configuration '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}'
```

remember to create s3, ec2, iam all access to your main role

add role to github env 

Settings → Secrets → New repository secret
AWS_ROLE_ARN = arn:aws:iam::<your-account-id>:role/github-actions



get the local file aws_role_arn and ^


check ci 1 

## Destroy all 


```bash
# set once
USERNAME=josephmachado

# destroy sandbox
terraform -chdir=terraform init -backend-config="key=sandbox/$USERNAME/terraform.tfstate"
terraform -chdir=terraform destroy -auto-approve -var-file="envs/sandbox.tfvars" -var="environment=sandbox-$USERNAME"

# destroy dev
terraform -chdir=terraform init -backend-config="key=dev/terraform.tfstate"
terraform -chdir=terraform destroy -auto-approve -var-file="envs/dev.tfvars"

# destroy prod
terraform -chdir=terraform init -backend-config="key=prod/terraform.tfstate"
terraform -chdir=terraform destroy -auto-approve -var-file="envs/prod.tfvars"

# destroy bootstrap last
terraform -chdir=terraform/bootstrap init
terraform -chdir=terraform/bootstrap destroy -auto-approve
```

new text1
