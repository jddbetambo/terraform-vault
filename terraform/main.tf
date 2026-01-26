########################################################
### RESOURCES PROVISION ###
#######################################################

# Key Pair resource

resource "aws_key_pair" "Key_pair" {
  key_name   = "key_pair_name"
  public_key = file("~/.ssh/${var.Key_Pair_Name}.pub")
}

# IAM Policies resource : ec2_read_only, Metadata

resource "aws_iam_policy" "ec2_read_only_and_metadata_policy" {
  name        = "EC2ReadOnlyAndMetadataPolicy"
  description = "Read-only access to EC2 resources and Metadata"
  policy = file("./ec2-policy.json")
}

# Create the IAM Role
resource "aws_iam_role" "ec2_read_only_and_metadata_role" {
  name               = "Ec2ReadOnlyRole"
  assume_role_policy = file("./ec2-role.json")
}

# Attach the Policy to the Role
resource "aws_iam_role_policy_attachment" "attach_ec2_read_only_metatda" {
  policy_arn = aws_iam_policy.ec2_read_only_and_metadata_policy.arn
  role       = aws_iam_role.ec2_read_only_and_metadata_role.name
}

# Create the Instance Profile to be attached to ec2 instances
resource "aws_iam_instance_profile" "ec2_read_only_metadata_profile" {
  name = "Ec2ReadOnlyInstanceMetadataProfile"
  role = aws_iam_role.ec2_read_only_and_metadata_role.name
}

# KMS Key for Vault auto-unseal
resource "aws_kms_key" "vault_unseal" {
  description             = "KMS key for Vault auto-unseal"
  deletion_window_in_days = 30
  enable_key_rotation     = true

  tags = {
    Name = "vault-unseal-kms-key"
  }
}


# ALB, target group, listener
resource "aws_lb" "vault" {
  name               = "vault-alb"
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = [aws_subnet.Public-Subnet-Vault-1.id, aws_subnet.Public-Subnet-Vault-2.id]

  tags = {
    Name = "vault-alb"
  }
}

resource "aws_lb_target_group" "vault" {
  name     = "vault-tg"
  port     = 8200
  protocol = "HTTP"
  vpc_id   = aws_vpc.VPC-Vault.id

  health_check {
    path                = "/v1/sys/health"
    matcher             = "200,429,472"
    interval            = 10
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = {
    Name = "vault-tg"
  }
}

resource "aws_lb_listener" "vault_https" {
  load_balancer_arn = aws_lb.vault.arn
  port              = 80 # Change to 443 in production
  protocol          = "HTTP" #HTTP for simplicity; change to HTTPS in production
  #ssl_policy        = "ELBSecurityPolicy-2016-08" # Uncomment for HTTPS
  #certificate_arn   = var.alb_certificate_arn # Uncomment for HTTPS

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.vault.arn
  }
}


# ec2 Instances

resource "aws_instance" "my_instances" {
  count                  = length(var.instance_names)
  ami                    = var.ami[var.AVAILABLE_REGIONS[var.AWS_REGIONS_INDEX]].Vault
  instance_type          = lookup(var.InstanceType, "Vault")
  subnet_id              = aws_subnet.Public-Subnet-Vault-1.id
  vpc_security_group_ids = ["${aws_security_group.Vault-SG.id}"]
  iam_instance_profile   = aws_iam_instance_profile.ec2_read_only_metadata_profile.name
  key_name               = aws_key_pair.Key_pair.key_name

  user_data = <<-EOF
              #!/bin/bash
              ${file("../scripts/install_vault_on_aws.sh")}
              EOF

  tags = {
    Name = element(var.instance_names, count.index)
    "vault-cluster" = var.cluster_tag_value
    CreationDate = formatdate("DD MMM YYYY hh:mm ZZZ", timestamp())
  }
}

# Target group attachment
resource "aws_lb_target_group_attachment" "vault" {
  count            = length(aws_instance.my_instances)
  target_group_arn = aws_lb_target_group.vault.arn
  target_id        = aws_instance.my_instances[count.index].id
  port             = 8200
}
