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
    external = {
      source  = "hashicorp/external"
      version = "~> 2.3.3"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.14.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.32.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.15.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.5.1"
    }
  }
}