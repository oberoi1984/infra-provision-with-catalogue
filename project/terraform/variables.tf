variable "region" {}
variable "instance_type" {}
variable "ami_id" {}
#variable "instance_count" {}
variable "security_group" {}
variable "key_pair" {}
variable "subnet_id" {}
variable "owner" {}
variable "project" {}
variable "environment" {}
variable "instance_count" {
  type = number 
  default = 1
}

