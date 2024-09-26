module "aws" {
  source       = "../../modules/aws"
  aws_region   = var.aws_region
  aws_profile_name = var.aws_profile_name
}

module "vpc" {
  source       = "../../modules/vpc"
  project_name = var.eks_name
  region       = var.aws_region
  vpc_cidr     = var.vpc_cidr
  depends_on = [module.aws]
}

module "eks" {
  source     = "../../modules/eks"
  eks_name = var.eks_name
  vpc_id     = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
  eks_version = var.eks_version
  node_instance_types = var.node_instance_types
  node_group_min_size = var.node_group_min_size
  node_group_max_size = var.node_group_max_size
  node_group_desired_size = var.node_group_desired_size
  depends_on = [module.vpc]
}

resource "null_resource" "wait_for_cluster" {
  depends_on = [module.eks]

  provisioner "local-exec" {
    command = <<-EOT
      #!/bin/bash
      max_retries=10
      counter=0
      until kubectl get serviceaccount default -n kube-system >/dev/null 2>&1; do
        if [ $counter -eq $max_retries ]; then
          echo "Failed to connect to EKS cluster after $max_retries attempts."
          exit 1
        fi
        counter=$((counter+1))
        echo "Waiting for EKS cluster to become accessible... (Attempt $counter/$max_retries)"
        sleep 5
      done
      echo "Successfully connected to EKS cluster!"
    EOT
  }
}

################################################################################
# Providers
################################################################################
data "aws_eks_cluster" "cluster" {
  depends_on = [null_resource.wait_for_cluster]
  name = module.eks.cluster_name
}

data "aws_eks_cluster_auth" "cluster" {
  depends_on = [null_resource.wait_for_cluster]
  name = module.eks.cluster_name
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
    command     = "aws"
  }
}

provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.cluster.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
      command     = "aws"
    }
  }
}

provider "kubectl" {
  apply_retry_count      = 5
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
  load_config_file       = false
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
    command     = "aws"
  }
}

# provider "kubernetes" {
#   config_path = "~/.kube/config"
# }

# provider "helm" {
#   kubernetes {
#     config_path = "~/.kube/config"  # 或者你的 kubeconfig 文件的实际路径
#   }
# }

# provider "kubectl" {
#   config_path = "~/.kube/config"
# }


module "eksaddon" {
  source       = "../../modules/eksaddon"
  eks_name = var.eks_name
  aws_account_id       = module.aws.account_id
  eks_cluster_oidc_issuer     = module.eks.eks_iam_openid_connect_provider_url
  depends_on = [module.eks]
}

module "ekslb" {
  source       = "../../modules/ekslb"
  eks_name = var.eks_name
  aws_account_id       = module.aws.account_id
  eks_cluster_oidc_issuer     = module.eks.eks_iam_openid_connect_provider_url
  aws_region = var.aws_region
  vpc_id = module.vpc.vpc_id
  depends_on = [module.eks, module.eksaddon]
}

module "karpenter" {
  source       = "../../modules/karpenter"
  eks_name = var.eks_name
  aws_account_id       = module.aws.account_id
  eks_cluster_oidc_issuer     = module.eks.eks_iam_openid_connect_provider_url
  eks_endpoint = module.eks.cluster_endpoint
  eks_node_group_role_arn = module.eks.node_iam_role_arn
  eks_node_group_role_name = module.eks.node_iam_role_name
  depends_on = [module.eks, module.eksaddon, module.ekslb]
}

module "s3" {
  source       = "../../modules/s3"
  eks_name = var.eks_name
  aws_account_id       = module.aws.account_id
  eks_cluster_oidc_issuer     = module.eks.eks_iam_openid_connect_provider_url
  aws_region = var.aws_region
  eks_node_iam_role_name = module.eks.node_iam_role_name
  eks_karpenter_iam_role_name = module.karpenter.karpenter_iam_role_name
  depends_on = [module.eks, module.eksaddon, module.karpenter]
}

module "efs" {
  source     = "../../modules/efs"
  eks_name = module.eks.cluster_name
  vpc_id = module.vpc.vpc_id
  eks_cluster_security_group_id = module.eks.eks_cluster_security_group_id
  subnet_ids = module.eks.subnet_ids
  depends_on = [ module.eks, module.eksaddon ]
}

module "monitoring" {
  source     = "../../modules/monitor"
  depends_on = [ module.eks, module.eksaddon, module.ekslb ]
}

module "cromwell" {
  source     = "../../modules/cromwell"
  aws_region = var.aws_region
  aws_account_id       = module.aws.account_id
  eks_cluster_oidc_issuer     = module.eks.eks_iam_openid_connect_provider_url
  efs_pvc = module.efs.efs_pvc
  s3_pvc = module.s3.s3_pvc
  eks_name = module.eks.cluster_name
  depends_on = [ module.eks, module.eksaddon, module.ekslb, module.efs, module.s3 ]
}

################################################################################
# 初始化 EKS 集群的 providers
################################################################################
# data "aws_eks_cluster_auth" "this" {
#   depends_on = [ module.eks ]
#   name = module.eks.cluster_name
# }

# provider "helm" {
#   kubernetes {
#     host                   = aws_eks_cluster.eks_cluster.endpoint
#     cluster_ca_certificate = base64decode(aws_eks_cluster.eks_cluster.certificate_authority[0].data)
#     exec {
#       api_version = "client.authentication.k8s.io/v1beta1"
#       args        = ["eks", "get-token", "--cluster-name", aws_eks_cluster.eks_cluster.name]
#       command     = "aws"
#     }
#   }
# }



# provider "kubectl" {
#   host                   = aws_eks_cluster.eks_cluster.endpoint
#   cluster_ca_certificate = base64decode(aws_eks_cluster.eks_cluster.certificate_authority[0].data)
#   load_config_file       = false
#   exec {
#     api_version = "client.authentication.k8s.io/v1beta1"
#     args        = ["eks", "get-token", "--cluster-name", aws_eks_cluster.eks_cluster.name]
#     command     = "aws"
#   }
#   apply_retry_count = 3
# }





# module "cromwell" {
#   source     = "../../modules/cromwell"
#   aws_region = var.aws_region
#   ecr_repository_url = module.eks.ecr_repository_url
#   efs_pvc = module.efs.efs_pvc
#   s3_pvc = module.s3.s3_pvc
#   cluster_name = module.eks.cluster_name
#   cluster_endpoint = module.eks.cluster_endpoint
#   cluster_ca_certificate_data = module.eks.kubeconfig_certificate_authority_data
#   eks_iam_openid_connect_provider_url = module.eks.eks_iam_openid_connect_provider_url
#   eks_iam_openid_connect_provider_arn = module.eks.eks_iam_openid_connect_provider_arn
  
# }

# module "test" {
#   source     = "../../modules/test"
#   s3_pvc = module.s3.s3_pvc
#   cluster_name = module.eks.cluster_name
#   cluster_endpoint = module.eks.cluster_endpoint
#   cluster_ca_certificate_data = module.eks.kubeconfig_certificate_authority_data
# }