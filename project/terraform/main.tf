provider "aws" {
  region = var.region
  profile = "default"
}

resource "aws_instance" "ec2" {
  count                  = var.instance_count
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id               = var.subnet_id
  vpc_security_group_ids  = [var.security_group]
  key_name                = var.key_pair

  tags = {
    Name        = "EC2-Instance-${var.project}-${var.environment}-${count.index}"
    Owner       = var.owner
    Project     = var.project
    Environment = var.environment
  }
}

