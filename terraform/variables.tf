# General
variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "project_prefix" {
  type    = string
  default = "prog8870-final"
}

variable "environment" {
  type    = string
  default = "dev"
}

# EC2 configuration
variable "ec2_ami_id" {
  type        = string
  description = "AMI ID for EC2 instance (e.g. Amazon Linux 2)"
}

variable "ec2_instance_type" {
  type    = string
  default = "t3.micro"
}

variable "ec2_key_name" {
  type        = string
  description = "Existing EC2 key pair name"
}

# RDS configuration
variable "db_name" {
  type        = string
  description = "Initial MySQL DB name"
}

variable "db_username" {
  type        = string
  description = "RDS master username"
}

variable "db_password" {
  type        = string
  sensitive   = true
  description = "RDS master password"
}
