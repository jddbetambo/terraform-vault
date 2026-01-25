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


# ec2 Instances

resource "aws_instance" "my_instances" {
  count                  = length(var.instance_names)
  ami                    = var.ami[var.AVAILABLE_REGIONS[var.AWS_REGIONS_INDEX]].Vault
  instance_type          = lookup(var.InstanceType, "Vault")
  subnet_id              = aws_subnet.Public-Subnet-Vault.id
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
