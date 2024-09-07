terraform {
  # specify minimum version of Terraform 
  required_version = "> 1.9.0"
  required_providers {
    aws = {
      source = "hashicorp/aws"
      #  Lock version to prevent unexpected problems
      version = "5.64.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2.2"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.32.0"
    }
  }
}


data "aws_eks_cluster_auth" "this" {
  name = var.cluster_name
}

provider "kubernetes" {
  host                   = var.cluster_endpoint
  cluster_ca_certificate = base64decode(var.cluster_ca_certificate_data)
  token                  = data.aws_eks_cluster_auth.this.token
}