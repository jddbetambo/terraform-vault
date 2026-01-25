variable "AVAILABLE_REGIONS" {
  type = map(string)

  default = {
    "1" = "us-east-1"
    "2" = "us-east-2"
    "3" = "us-west-1"
    "4" = "us-west-2"
  }
}

variable "AWS_REGIONS_INDEX" {
  type        = string
  description = "Available Regions: [1] us-east-1, [2] us-east-2, [3] us-west-1, [4] us-west-2"

  validation {
    condition     = can(regex("^(1|2|3|4)$", var.AWS_REGIONS_INDEX))
    error_message = "Please enter a value between 1 and 4"
  }

  default = 1 // Insfrastructure will be deployed in us-east-1
}


variable "ami" {
  type = map(object({
    Vault = string //Ubuntu Server 22.04 LTS
  }))

  description = "AMIs Reserved for the project"

  default = {
    us-east-1 = {
      Vault = "ami-005fc0f236362e99f"
    },
    us-east-2 = {
      Vault = "ami-00eb69d236edcfaf8"  
    },
    us-west-1 = {
      Vault = "ami-0819a8650d771b8be"
    },
    us-west-2 = {
      Vault = "ami-0b8c6b923777519db"
    }
  }
}

# Instances types to be used

variable "InstanceType" {
  type        = map(string)
  description = "# Instances types to be used on the JavaApp Project"

  default = {
    Vault = "t3.medium"
  }
}


# EC2 instances for Environment (env)
/* variable "instance_count" {
  description = "Number of EC2 instances for Env"
  type        = number
  default     = 3
} */

variable "instance_names" {
  description = "List of EC2 instance names for Env"
  type        = list(string)
  default     = ["Node-1", "Node-2", "Node-3", "Node-4"]
}

variable "EC2_iam_role" {
  type        = string
  description = "EC2 IAM role to be used"
  default = "Ec2AdminRole"
}


variable "Key_Pair_Name" {
  type        = string
  description = "Your key pair file name"
  default = "my_ssh_key"
}

variable "vault_port" {
  description = "Vault SG Ports"
  type = list(number)
  default = [ 22, 8200, 8201 ]
}

variable "cluster_tag_value" {
  description = "The value of the cluster tag to be used for Vault instances"
  type        = string
  default     = "vault-prod-cluster"
}
