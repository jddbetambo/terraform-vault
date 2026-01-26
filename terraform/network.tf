########################################################
### NETWORKING ###
#######################################################

# VPC
resource "aws_vpc" "VPC-Vault" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = "true"
  enable_dns_hostnames = "true"

  tags = {
  Name = "VPC-Vault" 
  }
}


# Public Subnet 1
resource "aws_subnet" "Public-Subnet-Vault-1" {
  vpc_id                  = aws_vpc.VPC-Vault.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = "true" # This is what makes it a public subnet
  availability_zone       = "${var.AVAILABLE_REGIONS[var.AWS_REGIONS_INDEX]}a"
  tags = {
    Name = "Public-Subnet-Vault-1"
  }
}

# Public Subnet 2
resource "aws_subnet" "Public-Subnet-Vault-2" {
  vpc_id                  = aws_vpc.VPC-Vault.id
  cidr_block              = "10.0.2.0/24"
  map_public_ip_on_launch = "true" # This is what makes it a public subnet
  availability_zone       = "${var.AVAILABLE_REGIONS[var.AWS_REGIONS_INDEX]}b"
  tags = {
    Name = "Public-Subnet-Vault-2"
  }
}

# Private Subnet 1
resource "aws_subnet" "Private-Subnet-Vault-1" {
  vpc_id            = aws_vpc.VPC-Vault.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "${var.AVAILABLE_REGIONS[var.AWS_REGIONS_INDEX]}a"
  tags = {
    Name = "Private-Subnet-Vault-1"
  }
}

# Private Subnet 2
resource "aws_subnet" "Private-Subnet-Vault-2" {
  vpc_id            = aws_vpc.VPC-Vault.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = "${var.AVAILABLE_REGIONS[var.AWS_REGIONS_INDEX]}b"
  tags = {
    Name = "Private-Subnet-Vault-2"
  }
}

# Add internet gateway
resource "aws_internet_gateway" "Vault-IGW" {
  vpc_id = aws_vpc.VPC-Vault.id
  tags = {
    Name = "Vault-IGW"
  }
}

# Public routes
resource "aws_route_table" "Vault-Public-CRT" {
  vpc_id = aws_vpc.VPC-Vault.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.Vault-IGW.id
  }

  tags = {
    Name = "Vault-Public-CRT"
  }
}

# PUBLIC ROUTE ASSOCIATION
resource "aws_route_table_association" "public_1" {
  subnet_id      = aws_subnet.Public-Subnet-Vault-1.id
  route_table_id = aws_route_table.Vault-Public-CRT.id
}

resource "aws_route_table_association" "public_2" {
  subnet_id      = aws_subnet.Public-Subnet-Vault-2.id
  route_table_id = aws_route_table.Vault-Public-CRT.id
}

