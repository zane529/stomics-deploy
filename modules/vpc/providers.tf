terraform {
  # specify minimum version of Terraform 
  required_version = "> 1.9.0"
  required_providers {
    aws = {
      source = "hashicorp/aws"
      #  Lock version to prevent unexpected problems
      version = "5.64.0"
    }
  }
}