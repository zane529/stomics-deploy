output "cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = aws_eks_cluster.eks_cluster.endpoint
}

output "cluster_name" {
  description = "Kubernetes Cluster Name"
  value       = aws_eks_cluster.eks_cluster.name
}

# 输出 kubeconfig 证书权限
output "kubeconfig_certificate_authority_data" {
  value = aws_eks_cluster.eks_cluster.certificate_authority[0].data
}

# 输出 EKS 的安全组
output "eks_cluster_security_group_id" {
  value = aws_eks_cluster.eks_cluster.vpc_config[0].cluster_security_group_id
}

# 输出 EKS 集群的所有子网ID
output "subnet_ids" {
  value = aws_eks_cluster.eks_cluster.vpc_config[0].subnet_ids
}

# 输出 EKS 集群的 Node group 的 role
output "node_iam_role_name" {
  value = aws_iam_role.eks_node_group_role.name
}

# 输出 EKS 集群的 Karpenter role
output "karpenter_iam_role_name" {
  value = module.karpenter_irsa.iam_role_name
}

# 输出 ECR 的 URL
output "ecr_repository_url" {
  value = aws_ecr_repository.ecr.repository_url
}

# 输出 OIDC 的 URL
output "eks_iam_openid_connect_provider_url" {
  value = aws_eks_cluster.eks_cluster.identity[0].oidc[0].issuer
}
# 输出 OIDC 的 ARN
output "eks_iam_openid_connect_provider_arn" {
  value = replace(aws_eks_cluster.eks_cluster.identity[0].oidc[0].issuer, "https://", "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/")
}