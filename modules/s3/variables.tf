variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "eks_node_iam_role_name" {
  description = "EKS Node iam role name"
  type        = string
}

variable "eks_karpenter_iam_role_name" {
  description = "EKS Node iam role name"
  type        = string
}

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

variable "k8s_namespace" {
  description = "The k8s namespace about pods."
  type        = string
  default = "default"
}

variable "eks_iam_openid_connect_provider_url" {
  description = "OIDC URL"
  type        = string
}

variable "eks_iam_openid_connect_provider_arn" {
  description = "OIDC ARN"
  type        = string
}