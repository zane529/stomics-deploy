################################################################################
# 通过 EKS addon 新增插件
################################################################################
resource "aws_eks_addon" "vpc_cni" {
  depends_on = [aws_eks_cluster.eks_cluster, aws_eks_node_group.eks_node_group]
  cluster_name = aws_eks_cluster.eks_cluster.name
  addon_name   = "vpc-cni"
  addon_version = "v1.18.3-eksbuild.2"
  resolve_conflicts_on_create = "OVERWRITE"
}

# resource "aws_eks_addon" "pod_identity_agent" {
#   cluster_name = aws_eks_cluster.eks_cluster.name
#   addon_name   = "eks-pod-identity-agent"
#   addon_version = "v1.3.2-eksbuild.2"
#   resolve_conflicts_on_create = "OVERWRITE"
# }

resource "aws_eks_addon" "amazon_s3_csi_driver" {
  depends_on = [aws_eks_cluster.eks_cluster, aws_eks_node_group.eks_node_group]
  cluster_name = aws_eks_cluster.eks_cluster.name
  addon_name   = "aws-mountpoint-s3-csi-driver"
  addon_version = "v1.8.0-eksbuild.1"
  resolve_conflicts_on_create = "OVERWRITE"
}

resource "aws_eks_addon" "amazon_efs_csi_driver" {
  depends_on = [aws_eks_cluster.eks_cluster, aws_eks_node_group.eks_node_group]
  cluster_name = aws_eks_cluster.eks_cluster.name
  addon_name   = "aws-efs-csi-driver"
  addon_version = "v2.0.7-eksbuild.1"
  resolve_conflicts_on_create = "OVERWRITE"
}

resource "aws_eks_addon" "amazon_ebs_csi_driver" {
  depends_on = [aws_eks_cluster.eks_cluster, aws_eks_node_group.eks_node_group]
  cluster_name = aws_eks_cluster.eks_cluster.name
  addon_name   = "aws-ebs-csi-driver"
  addon_version = "v1.34.0-eksbuild.1"
  resolve_conflicts_on_create = "OVERWRITE"
}
