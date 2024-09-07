variable "cluster_name" {
  description = "The EKS Cluster's name"
  type        = string
}

variable "cluster_endpoint" {
  description = "The EKS Cluster's enpoint"
  type        = string
}

variable "cluster_ca_certificate_data" {
  description = "The EKS cluster_ca_certificate_data"
  type        = string
}

variable "project_name" {
  description = "Name of the EKS cluster"
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