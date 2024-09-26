variable "aws_region" {
  description = "AWS region"
  type        = string
}
variable "s3_pvc" {
  description = "s3 pvc"
  type        = string
}
variable "efs_pvc" {
  description = "efs pvc"
  type        = string
}
variable "eks_name" {
  description = "The EKS Cluster's name"
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
variable "k8s_namespace" {
  description = "The k8s namespace about pods."
  type        = string
  default = "default"
}