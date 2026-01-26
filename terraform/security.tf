# Vault Security Group
resource "aws_security_group" "Vault-SG" {
  vpc_id = aws_vpc.VPC-Vault.id
  name        = "vault-cluster-sg"
  description = "Security group for Vault cluster"


  # Vault API from ALB only
  ingress {
    description      = "Vault API from ALB"
    from_port        = 8200
    to_port          = 8200
    protocol         = "tcp"
    security_groups  = [aws_security_group.alb.id]
  }

  # Raft between nodes
  ingress {
    description = "Vault Raft"
    from_port   = 8201
    to_port     = 8201
    protocol    = "tcp"
    self        = true
  }

  # SSH from admin (optional)
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
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


# Security Group for ALB
resource "aws_security_group" "alb" {
  name        = "vault-alb-sg"
  description = "ALB for Vault"
  vpc_id      = aws_vpc.VPC-Vault.id

  ingress {
    description = "HTTP from admin / clients" # In production, use HTTPS
    from_port   = 80 # Change to 443 in production
    to_port     = 80 # Change to 443 in production
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "vault-alb-sg"
  }
}