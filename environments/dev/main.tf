module "aws" {
  source       = "../../modules/aws"
  aws_region   = var.aws_region
  aws_profile_name = var.aws_profile_name
}

module "vpc" {
  source       = "../../modules/vpc"
  project_name = var.project_name
  region       = var.aws_region
  vpc_cidr     = var.vpc_cidr
}

module "eks" {
  source     = "../../modules/eks"
  aws_region = var.aws_region
  project_name = var.project_name
  vpc_id     = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
  eks_version = var.eks_version
  node_instance_types = var.node_instance_types
  node_group_min_size = var.node_group_min_size
  node_group_max_size = var.node_group_max_size
  node_group_desired_size = var.node_group_desired_size
}

module "efs" {
  source     = "../../modules/efs"
  cluster_name = module.eks.cluster_name
  cluster_endpoint = module.eks.cluster_endpoint
  cluster_ca_certificate_data = module.eks.kubeconfig_certificate_authority_data
  project_name = var.project_name
  vpc_id = module.vpc.vpc_id
  eks_cluster_security_group_id = module.eks.eks_cluster_security_group_id
  subnet_ids = module.eks.subnet_ids
}

module "s3" {
  source     = "../../modules/s3"
  aws_region = var.aws_region
  cluster_name = module.eks.cluster_name
  cluster_endpoint = module.eks.cluster_endpoint
  cluster_ca_certificate_data = module.eks.kubeconfig_certificate_authority_data
  project_name = var.project_name
  eks_node_iam_role_name = module.eks.node_iam_role_name
  eks_karpenter_iam_role_name = module.eks.karpenter_iam_role_name
  eks_iam_openid_connect_provider_url = module.eks.eks_iam_openid_connect_provider_url
  eks_iam_openid_connect_provider_arn = module.eks.eks_iam_openid_connect_provider_arn
}

module "cromwell" {
  source     = "../../modules/cromwell"
  aws_region = var.aws_region
  ecr_repository_url = module.eks.ecr_repository_url
  efs_pvc = module.efs.efs_pvc
  s3_pvc = module.s3.s3_pvc
  cluster_name = module.eks.cluster_name
  cluster_endpoint = module.eks.cluster_endpoint
  cluster_ca_certificate_data = module.eks.kubeconfig_certificate_authority_data
  eks_iam_openid_connect_provider_url = module.eks.eks_iam_openid_connect_provider_url
  eks_iam_openid_connect_provider_arn = module.eks.eks_iam_openid_connect_provider_arn
}

# module "test" {
#   source     = "../../modules/test"
#   s3_pvc = module.s3.s3_pvc
#   cluster_name = module.eks.cluster_name
#   cluster_endpoint = module.eks.cluster_endpoint
#   cluster_ca_certificate_data = module.eks.kubeconfig_certificate_authority_data
# }