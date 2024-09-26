################################################################################
# VPC CSI
################################################################################
resource "aws_eks_addon" "vpc_cni" {
  cluster_name = var.eks_name
  addon_name   = "vpc-cni"
  addon_version = "v1.18.3-eksbuild.2"
  resolve_conflicts_on_create = "OVERWRITE"
}

################################################################################
# S3 CSI
################################################################################
resource "aws_eks_addon" "amazon_s3_csi_driver" {
  cluster_name = var.eks_name
  addon_name   = "aws-mountpoint-s3-csi-driver"
  addon_version = "v1.8.0-eksbuild.1"
  resolve_conflicts_on_create = "OVERWRITE"
}

################################################################################
# EFS CSI
################################################################################
resource "aws_eks_addon" "amazon_efs_csi_driver" {
  cluster_name = var.eks_name
  addon_name   = "aws-efs-csi-driver"
  addon_version = "v2.0.7-eksbuild.1"
  resolve_conflicts_on_create = "OVERWRITE"
}


################################################################################
# 创建 IAM 角色
################################################################################
resource "aws_iam_role" "ebs_csi_role" {
  name = "${var.eks_name}-ebs-csi-driver-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = "arn:aws:iam::${var.aws_account_id}:oidc-provider/${replace(var.eks_cluster_oidc_issuer, "https://", "")}"
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${replace(var.eks_cluster_oidc_issuer, "https://", "")}:sub": "system:serviceaccount:kube-system:ebs-csi-controller-sa"
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
  depends_on = [ aws_iam_role_policy_attachment.ebs_csi_policy_attachment ]
  cluster_name = var.eks_name
  addon_name   = "aws-ebs-csi-driver"
  addon_version = "v1.34.0-eksbuild.1"
  resolve_conflicts_on_create = "OVERWRITE"
  service_account_role_arn = aws_iam_role.ebs_csi_role.arn
}