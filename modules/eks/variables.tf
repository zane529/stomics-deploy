variable "aws_region" {
  description = "The Region of AWS"
  type        = string
}

variable "vpc_id" {
  description = "The ID of the VPC"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of subnet IDs"
  type        = list(string)
}

variable "project_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "eks_version" {
  description = "Kubernetes version for the EKS cluster"
  type        = string
  default     = "1.30"
}

variable "node_instance_types" {
  description = "List of instance types for the EKS managed node group"
  type        = list(string)
  default     = ["c6i.large"]
}

variable "node_group_min_size" {
  description = "Minimum number of nodes in the EKS managed node group"
  type        = number
  default     = 3
}

variable "node_group_max_size" {
  description = "Maximum number of nodes in the EKS managed node group"
  type        = number
  default     = 10
}

variable "node_group_desired_size" {
  description = "Desired number of nodes in the EKS managed node group"
  type        = number
  default     = 3
}

variable "node_group_ebs_size" {
  description = "The ebs size of nodes in the EKS managed node group, (GB)"
  type        = number
  default     = 80
}

variable "karpenter_version" {
  description = "Karpenter Version"
  default     = "0.16.3"
  type        = string
}

variable "karpenter_namespace" {
  description = "The K8S namespace to deploy Karpenter into"
  default     = "karpenter"
  type        = string
}

variable "karpenter_ec2_instance_types" {
  description = "List of instance types that can be used by Karpenter"
  type        = list(string)
  default = [
  "m5.large",
  "m5a.large",
  "m5.xlarge",
  "m5a.xlarge",
  "m5.2xlarge",
  "m5a.2xlarge",
  "m6i.large",
  "m6i.xlarge",
  "m6i.2xlarge",
]
}

variable "karpenter_ec2_arch" {
  description = "List of CPU architecture for the EC2 instances provisioned by Karpenter"
  type        = list(string)
  default     = ["amd64"]
}

variable "karpenter_ec2_capacity_type" {
  description = "EC2 provisioning capacity type"
  type        = list(string)
  default     = ["spot", "on-demand"]
}

variable "karpenter_ttl_seconds_after_empty" {
  description = "Node lifetime after empty"
  type        = number
  default = 300
}

variable "karpenter_ttl_seconds_until_expired" {
  description = "Node maximum lifetime"
  type        = number
  default = 604800
}

variable "vpc_private_subnet_count" {
  type        = number
  default     = 3
}