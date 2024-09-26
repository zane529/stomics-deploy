variable "eks_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "aws_account_id" {
  description = "The account id of aws."
  type        = string
}

variable "eks_cluster_oidc_issuer" {
  description = "The oidc issuer of eks cluster."
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "vpc_id" {
  description = "AWS region"
  type        = string
}