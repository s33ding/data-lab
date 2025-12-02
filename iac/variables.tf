variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.xlarge"
}

variable "key_pair_name" {
  description = "AWS key pair name for EC2 access"
  type        = string
  default     = "fedora-main-kafka"
}

variable "existing_vpc_id" {
  description = "ID of existing VPC where RDS is located"
  type        = string
  default     = "vpc-08f71cff199dc1fc6"
}

variable "existing_subnet_id" {
  description = "ID of existing subnet in the VPC"
  type        = string
  default     = "subnet-0a8fdc075bd605e6a"
}

variable "existing_rds_identifier" {
  description = "Identifier of existing RDS instance"
  type        = string
  default     = "rds-prod"
}

variable "rds_secret_name" {
  description = "Name of the RDS secret in Secrets Manager"
  type        = string
  default     = "rds-master"
}
