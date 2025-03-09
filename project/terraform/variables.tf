variable "region" {}
variable "instance_type" {}
variable "ami_id" {}
#variable "instance_count" {}
variable "security_group" {
type = string
default = ""
}
variable "key_pair" {
type = string
default = ""
}
variable "subnet_id" {
type = string
default = ""
}
variable "owner" {}
variable "project" {}
variable "environment" {}
variable "instance_count" {
  type = number 
  default = 1
}

