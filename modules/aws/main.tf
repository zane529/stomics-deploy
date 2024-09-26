# specify local directory for AWS credentials
provider "aws" {
  region                   = var.aws_region
  profile                  = var.aws_profile_name
}

data "aws_caller_identity" "current" {}