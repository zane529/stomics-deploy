################################################################################
# VPC CSI
################################################################################
resource "aws_eks_addon" "vpc_cni" {
  depends_on = [aws_eks_cluster.eks_cluster, aws_eks_node_group.eks_node_group]
  cluster_name = aws_eks_cluster.eks_cluster.name
  addon_name   = "vpc-cni"
  addon_version = "v1.18.3-eksbuild.2"
  resolve_conflicts_on_create = "OVERWRITE"
}

################################################################################
# S3 CSI
################################################################################
resource "aws_eks_addon" "amazon_s3_csi_driver" {
  depends_on = [aws_eks_cluster.eks_cluster, aws_eks_node_group.eks_node_group]
  cluster_name = aws_eks_cluster.eks_cluster.name
  addon_name   = "aws-mountpoint-s3-csi-driver"
  addon_version = "v1.8.0-eksbuild.1"
  resolve_conflicts_on_create = "OVERWRITE"
}

################################################################################
# EFS CSI
################################################################################
resource "aws_eks_addon" "amazon_efs_csi_driver" {
  depends_on = [aws_eks_cluster.eks_cluster, aws_eks_node_group.eks_node_group]
  cluster_name = aws_eks_cluster.eks_cluster.name
  addon_name   = "aws-efs-csi-driver"
  addon_version = "v2.0.7-eksbuild.1"
  resolve_conflicts_on_create = "OVERWRITE"
}


################################################################################
# 创建 IAM 角色
################################################################################
resource "aws_iam_role" "ebs_csi_role" {
  name = "${aws_eks_cluster.eks_cluster.name}-ebs-csi-driver-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${replace(aws_eks_cluster.eks_cluster.identity[0].oidc[0].issuer, "https://", "")}"
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${replace(aws_eks_cluster.eks_cluster.identity[0].oidc[0].issuer, "https://", "")}:sub": "system:serviceaccount:kube-system:ebs-csi-controller-sa"
          }
        }
      },
    ]
  })
}

################################################################################
# 将策略附加到 ebs csi 角色
################################################################################
resource "aws_iam_role_policy_attachment" "ebs_csi_policy_attachment" {
  depends_on = [ aws_iam_role.ebs_csi_role ]
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
  role       = aws_iam_role.ebs_csi_role.name
}

################################################################################
# EBS CSI
################################################################################
resource "aws_eks_addon" "amazon_ebs_csi_driver" {
  depends_on = [aws_eks_cluster.eks_cluster, aws_eks_node_group.eks_node_group, aws_iam_role_policy_attachment.ebs_csi_policy_attachment]
  cluster_name = aws_eks_cluster.eks_cluster.name
  addon_name   = "aws-ebs-csi-driver"
  addon_version = "v1.34.0-eksbuild.1"
  resolve_conflicts_on_create = "OVERWRITE"
  service_account_role_arn = aws_iam_role.ebs_csi_role.arn
}