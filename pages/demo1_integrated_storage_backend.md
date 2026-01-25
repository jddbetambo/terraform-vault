# Deploying Integrated Storage Backend

<p align="center">
    <img src="../images/demo1.png">
</p>

## High-level architecture
- **3 EC2 instances** in the same VPC, same region.
- **Vault integrated storage (Raft)** for HA and data durability.
- **One load balancer** (optional but recommended) in front of the nodes.
- **TLS everywhere** (self-signed or ACM behind ALB).
- **Security groups** tightly scoped to:
    - Allow Vault API port (e.g. 8200) only from trusted sources / load balancer.
    - Allow Raft port (e.g. 8201) only between Vault nodes.

## Network and ports
Pick ports (defaults are fine)
- API: 8200/tcp
- Raft: 8201/tcp

Security group rules:
- Inbound 8200: from your admin IPs and/or load balancer.
- Inbound 8201: from the other Vault nodes’ security group only.
- SSH 22: from your admin IPs.


## 1. Prepare the EC2 instances

Below is a clean pattern:
- Terraform builds 3 EC2 instances, security group, IAM role.
- Each instance runs a cloud-init/user_data script that:
    - Installs Vault
    - Configures integrated storage (Raft)
    - Uses AWS auto-join based on tags to form the cluster.

## 2. Terraform: provider and basics

```bash
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}
```

## 2. Security group for Vault cluster
```bash
resource "aws_security_group" "vault" {
  name        = "vault-cluster-sg"
  description = "Security group for Vault cluster"
  vpc_id      = var.vpc_id

  # Vault API (from your IP / load balancer)
  ingress {
    description = "Vault API"
    from_port   = 8200
    to_port     = 8200
    protocol    = "tcp"
    cidr_blocks = [var.admin_cidr] # e.g. "x.x.x.x/32" or LB subnet
  }

  # Raft traffic (between nodes only)
  ingress {
    description = "Vault Raft"
    from_port   = 8201
    to_port     = 8201
    protocol    = "tcp"
    self        = true
  }

  # SSH (optional)
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.admin_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "vault-cluster-sg"
  }
}
```

## 3. IAM role so Vault can auto-join via AWS

```bash
resource "aws_iam_role" "vault" {
  name = "vault-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "vault" {
  name = "vault-ec2-describe"
  role = aws_iam_role.vault.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["ec2:DescribeInstances"]
      Resource = "*"
    }]
  })
}

resource "aws_iam_instance_profile" "vault" {
  name = "vault-ec2-instance-profile"
  role = aws_iam_role.vault.name
}
```

## 4. User data: install and configure Vault with integrated storage

You can download the bash script [here](../scripts/install_vault_on_aws.sh). Other Terraform scripts can be found in the directory called Terraform in this project.

## 5. What happens when you `terraform apply`
1. Terraform creates:
- Security group
- IAM role + instance profile
- 4 EC2 instances with the right tags

2. Each instance:
- Installs Vault
- Writes a Raft + auto-join config
- Starts vault.service

3. Vault nodes discover each other using:
- `auto_join = "provider=aws tag_key=vault-cluster tag_value=vault-prod-cluster addr_type=private_v4"`

You still need to:
- Run `vault operator init` once against any node (or via the load balancer if you add one).
- Unseal nodes (or configure AWS KMS auto-unseal later).

If you want to go one level further, we can:
- Add an NLB/ALB in Terraform in front of the 3 nodes.
- Wire in AWS KMS auto-unseal so the cluster comes up fully usable with zero manual unseal.

