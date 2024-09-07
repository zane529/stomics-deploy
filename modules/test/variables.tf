variable "s3_pvc" {
  description = "s3 pvc"
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