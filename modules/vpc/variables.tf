variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
}

variable "vpc_public_subnet_count" {
  type        = number
  default     = 3
}

variable "vpc_private_subnet_count" {
  type        = number
  default     = 3
}