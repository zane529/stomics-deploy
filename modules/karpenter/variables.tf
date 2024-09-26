variable "eks_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "eks_endpoint" {
  description = "Endpoint of the EKS cluster"
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

variable "eks_node_group_role_arn" {
  description = "EKS node group's role arn"
  type        = string
}

variable "eks_node_group_role_name" {
  description = "EKS node group's role name"
  type        = string
}

variable "karpenter_version" {
  description = "Karpenter Version"
  default     = "0.16.3"
  type        = string
}