################################################################################
# 本地变量
################################################################################
locals {
  s3_access_sa = "s3-access-sa"
}

################################################################################
# 创建 EFS 安全组
################################################################################
resource "random_id" "suffix" {
  byte_length = 6
}

resource "aws_s3_bucket" "s3" {
  bucket = "${var.project_name}-${var.aws_region}-${random_id.suffix.hex}"
}

################################################################################
# 配置 S3 访问权限
################################################################################
resource "aws_iam_policy" "s3_access" {
  name = "${var.project_name}_s3_access"
  path = "/"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetBucketLocation",
          "s3:ListBucket",
          "s3:ListBucketMultipartUploads"
        ]
        Resource = [aws_s3_bucket.s3.arn]
      },
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:DeleteObject",
          "s3:ListMultipartUploadParts",
          "s3:AbortMultipartUpload"
        ]
        Resource = ["${aws_s3_bucket.s3.arn}/*"]
      }
    ]
  })
}

################################################################################
# 创建 assume_role_policy
################################################################################
data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    condition {
      test     = "StringEquals"
      variable = "${replace(var.eks_iam_openid_connect_provider_url, "https://", "")}:sub"
      values   = ["system:serviceaccount:${var.k8s_namespace}:${local.s3_access_sa}"]
    }

    principals {
      identifiers = [var.eks_iam_openid_connect_provider_arn]
      type        = "Federated"
    }
  }
}

################################################################################
# 创建 S3 访问角色
################################################################################
resource "aws_iam_role" "s3_access_role" {
  depends_on = [ data.aws_iam_policy_document.assume_role_policy ]
  name = "${var.project_name}-eks-s3-access-role"
  # 允许 EKS Pod Identity Agent 承担此角色的信任关系
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
}

################################################################################
# 将 S3 访问权限 附加到 Node group，Karpenter，Pod 角色上
################################################################################

resource "aws_iam_role_policy_attachment" "s3_access_to_node_role" {
  role       = var.eks_node_iam_role_name
  policy_arn = aws_iam_policy.s3_access.arn
}

resource "aws_iam_role_policy_attachment" "s3_access_to_karpenter_role" {
  role       = var.eks_karpenter_iam_role_name
  policy_arn = aws_iam_policy.s3_access.arn
}

resource "aws_iam_role_policy_attachment" "s3_access_to_pod_role" {
  role       = aws_iam_role.s3_access_role.name
  policy_arn = aws_iam_policy.s3_access.arn
}

################################################################################
# 创创建 S3 ServiceAccount
################################################################################
resource "kubernetes_service_account" "s3_access_sa" {
  depends_on = [ aws_iam_role.s3_access_role ]
  metadata {
    name      = local.s3_access_sa
    namespace = var.k8s_namespace
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.s3_access_role.arn
    }
  }
}

################################################################################
# 创建 创建 Kubernetes PersistentVolume
################################################################################
resource "kubernetes_persistent_volume" "s3" {
  metadata {
    name = "s3-pv"
  }
  spec {
    capacity = {
      storage = "4800Gi"
    }
    access_modes = ["ReadWriteMany"]
    mount_options = [
      "uid=1000",
      "gid=2000",
      "allow-other",
      "allow-delete",
      "region ${var.aws_region}"
    ]
    persistent_volume_source {
      csi {
        driver = "s3.csi.aws.com"
        volume_handle = "s3-csi-driver-volume-${aws_s3_bucket.s3.id}"
        volume_attributes = {
          bucketName = aws_s3_bucket.s3.id
        }
      }
    }
  }
}

################################################################################
# 创建 Kubernetes PersistentVolumeClaim
################################################################################
resource "kubernetes_persistent_volume_claim" "s3" {

  metadata {
    name = "s3-pvc"
  }

  spec {
    access_modes = ["ReadWriteMany"]
    storage_class_name = ""

    resources {
      requests = {
        storage = "4800Gi"
      }
    }

    volume_name = kubernetes_persistent_volume.s3.id
  }
}