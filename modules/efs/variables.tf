variable "eks_name" {
  description = "The EKS Cluster's name"
  type        = string
}

variable "vpc_id" {
  description = "The ID of the VPC"
  type        = string
}

variable "eks_cluster_security_group_id" {
  description = "EKS Cluster security group id."
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs"
  type        = list(string)
}