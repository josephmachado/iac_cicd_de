input_bucket  = "my-input-dev-something-unique"
instance_type = "t3.micro"
# environment passed via -var="environment=sandbox-${{ github.actor }}" in CI
