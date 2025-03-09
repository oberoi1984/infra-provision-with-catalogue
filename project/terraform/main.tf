provider "aws" {
  region  = var.region
  profile = "default"
}

#  Fetch Default VPC
data "aws_vpc" "default" {
  default = true
}

#  Fetch Available Subnets in the Default VPC
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

#  Fetch Available AZs in the Region
data "aws_availability_zones" "available" {}

#  Select an Available Subnet If None is Provided
data "aws_subnet" "default" {
  id = length(data.aws_subnets.default.ids) > 0 ? tolist(data.aws_subnets.default.ids)[0] : ""
}

#  Generate a Unique Subnet CIDR to Avoid Conflicts
locals {
  base_cidr            = "172.31.0.0/16"  # Default AWS VPC CIDR
  used_subnets         = data.aws_subnets.default.ids
  new_subnet_index     = length(local.used_subnets) + 1
  available_cidr_block = cidrsubnet(local.base_cidr, 8, local.new_subnet_index)
}

#  Create a New Subnet ONLY IF No Existing Subnet is Available
resource "aws_subnet" "default_subnet" {
  count                    = var.subnet_id == "" && length(data.aws_subnets.default.ids) == 0 ? 1 : 0
  vpc_id                   = data.aws_vpc.default.id
  cidr_block               = local.available_cidr_block
  map_public_ip_on_launch  = true
  availability_zone        = data.aws_availability_zones.available.names[0]
}

#  Lookup an Existing Security Group If Provided
data "aws_security_group" "existing_sg" {
  count  = var.security_group == "" ? 0 : 1
  filter {
    name   = "group-name"
    values = [var.security_group]
  }
}

#  Create a Default Security Group If None Exists
resource "aws_security_group" "default_sg" {
  count       = var.security_group == "" ? 1 : 0
  name        = "default-sg"
  description = "Default security group for EC2"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#  Lookup an Existing Key Pair If Provided
data "aws_key_pair" "existing_key" {
  count  = var.key_pair == "" ? 0 : 1
  key_name = var.key_pair
}

#  Generate a New SSH Key Pair If None Exists
resource "tls_private_key" "generated_key" {
  count     = var.key_pair == "" ? 1 : 0
  algorithm = "RSA"
  rsa_bits  = 2048
}

# Save Private Key Locally
resource "local_file" "private_key" {
  count    = var.key_pair == "" ? 1 : 0
  content  = tls_private_key.generated_key[0].private_key_pem
  filename = "${path.module}/aws-key.pem"
}

# Create AWS Key Pair
resource "aws_key_pair" "default_key" {
  count      = var.key_pair == "" ? 1 : 0
  key_name   = "aws-generated-key"
  public_key = tls_private_key.generated_key[0].public_key_openssh
}


# Create EC2 Instance (Always Creates a New One)
resource "aws_instance" "ec2" {
  count = var.instance_count  # Allows multiple instances if needed

  ami           = var.ami_id
  instance_type = var.instance_type
  subnet_id     = var.subnet_id == "" ? (length(data.aws_subnets.default.ids) > 0 ? data.aws_subnet.default.id : aws_subnet.default_subnet[0].id) : var.subnet_id
  key_name      = var.key_pair == "" ? aws_key_pair.default_key[0].key_name : var.key_pair

  vpc_security_group_ids = var.security_group == "" ? [aws_security_group.default_sg[0].id] : [var.security_group]

  tags = {
    Name        = "EC2-Instance-${var.project}-${var.environment}-${count.index}"
    Owner       = var.owner
    Project     = var.project
    Environment = var.environment
  }
}
