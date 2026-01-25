
########################################################
### OUTPUT / RESUME ###
########################################################


###############################################################
# Network information
output "AWS_Network_Information" {
  description = "Network Information"
  value       = {"Region: " : var.AVAILABLE_REGIONS[var.AWS_REGIONS_INDEX],  
                    "Availability Zone: " : "${var.AVAILABLE_REGIONS[var.AWS_REGIONS_INDEX]}a",
                    "VPC Name: " : aws_vpc.VPC-Vault.tags.Name,
                    "VPC CIDR:" : aws_vpc.VPC-Vault.cidr_block,
                    "Public Subnet:" : aws_subnet.Public-Subnet-Vault.cidr_block,
                    "Private Subnet:" : aws_subnet.Private-Subnet-Vault.cidr_block,
                } 
}

###############################################################
# Common configuration
output "Global_Configuration" {
  description = "Global Configuration"
  value       = {"Key Pair Name: " : var.Key_Pair_Name
                    "IAM Policy: " : aws_iam_policy.ec2_read_only_and_metadata_policy.arn
                    "IAM Role: " : aws_iam_role.ec2_read_only_and_metadata_role.arn
                } 
}



