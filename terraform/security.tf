# Vault Security Group
resource "aws_security_group" "Vault-SG" {
  vpc_id = aws_vpc.VPC-Vault.id

  dynamic "ingress" {
    for_each = var.vault_port
    iterator = port 

    content {
      from_port = port.value
      to_port = port.value
      protocol = "tcp"
      cidr_blocks = [ "0.0.0.0/0" ]
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = {
    Name = "Vault-SG"
  }
}

