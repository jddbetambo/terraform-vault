# cloud-policy.hcl

# Allow read and create permissions for AWS secrets
path "aws-cloud/*" {
  capabilities = ["read", "create", "update", "delete", "list"]
}

# Allow read access to identity secrets
path "identity/*" {
  capabilities = ["read", "list"]
}

# Add any additional paths and capabilities as needed