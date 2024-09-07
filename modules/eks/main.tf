resource "random_id" "suffix" {
  byte_length = 6
}

locals {
  cluster_name = "${var.project_name}-eks-${random_id.suffix.hex}"
}

################################################################################
# 创建 EKS 集群角色
################################################################################
resource "aws_iam_role" "eks_cluster_role" {
  name = "${local.cluster_name}-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
      }
    ]
  })
}

################################################################################
# 附加 EKS 集群角色策略
################################################################################
resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  depends_on = [ aws_iam_role.eks_cluster_role ]
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster_role.name
}
resource "aws_iam_role_policy_attachment" "eks_service_policy" {
  depends_on = [ aws_iam_role.eks_cluster_role ]
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
  role       = aws_iam_role.eks_cluster_role.name
}

################################################################################
# 创建 EKS 集群
################################################################################
resource "aws_eks_cluster" "eks_cluster" {

  enabled_cluster_log_types = [
    "api",
    "audit",
    "authenticator",
    "controllerManager",
    "scheduler",
  ]

  name = local.cluster_name

  role_arn = aws_iam_role.eks_cluster_role.arn
  tags     = {}
  version  = var.eks_version

  timeouts {}

  vpc_config {
    # endpoint_private_access = true
    # endpoint_public_access  = true
    # public_access_cidrs = [
    #   "0.0.0.0/0",
    # ]
    subnet_ids = var.private_subnet_ids
  }

  depends_on = [aws_iam_role_policy_attachment.eks_cluster_policy, aws_iam_role_policy_attachment.eks_service_policy]
}

################################################################################
# 配置 Local machine 的 kubectl 认证信息
################################################################################

resource "null_resource" "gen_cluster_auth" {
  triggers = {
    cluster_name = aws_eks_cluster.eks_cluster.name
  }
  depends_on = [aws_eks_cluster.eks_cluster]
  provisioner "local-exec" {
    on_failure  = fail
    when        = create
    interpreter = ["/bin/bash", "-c"]
    command     = <<EOT
        echo -e "\x1B[32m Checking Authorization ${nonsensitive(aws_eks_cluster.eks_cluster.name)} ...should see Server Version: v${var.eks_version} \x1B[0m"
        sh ${path.module}/auth.sh ${nonsensitive(aws_eks_cluster.eks_cluster.name)}
        echo "************************************************************************************"
     EOT
  }
}

################################################################################
# 创建 Node Group 的 IAM 角色
################################################################################
resource "aws_iam_role" "eks_node_group_role" {
  depends_on = [aws_eks_cluster.eks_cluster]

  name = "${local.cluster_name}-node-role"

  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })
}

################################################################################
# 附加 Node Group 的 IAM 角色策略
################################################################################
resource "aws_iam_role_policy_attachment" "eks_worker_node_policy" {
  depends_on = [ aws_iam_role.eks_node_group_role ]
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_node_group_role.name
}

resource "aws_iam_role_policy_attachment" "eks_cni_policy" {
  depends_on = [ aws_iam_role.eks_node_group_role ]
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_node_group_role.name
}

resource "aws_iam_role_policy_attachment" "eks_container_registry_policy" {
  depends_on = [ aws_iam_role.eks_node_group_role ]
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_node_group_role.name
}

################################################################################
# 创建 Node Group
################################################################################
resource "aws_eks_node_group" "eks_node_group" {
  cluster_name    = aws_eks_cluster.eks_cluster.name
  node_group_name = "ng"
  node_role_arn   = aws_iam_role.eks_node_group_role.arn
  subnet_ids      = var.private_subnet_ids

  # 这里设置为 80GB，你可以根据需要调整
  disk_size = var.node_group_ebs_size

  scaling_config {
    desired_size = var.node_group_desired_size
    max_size     = var.node_group_max_size
    min_size     = var.node_group_min_size
  }

  instance_types = var.node_instance_types

  # 添加这个块来设置标签
  tags = {
    "Name" = "${local.cluster_name}-worker-node"
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_worker_node_policy,
    aws_iam_role_policy_attachment.eks_cni_policy,
    aws_iam_role_policy_attachment.eks_container_registry_policy,
    aws_eks_cluster.eks_cluster
  ]
}

################################################################################
# 开启 EKS 集群的 OIDC
################################################################################
data "tls_certificate" "eks_oidc" {
  depends_on = [aws_eks_cluster.eks_cluster]
  url = aws_eks_cluster.eks_cluster.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "eks_oidc" {
  depends_on = [data.tls_certificate.eks_oidc]
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks_oidc.certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.eks_cluster.identity[0].oidc[0].issuer
}

################################################################################
# 初始化 EKS 集群的 providers
################################################################################
data "aws_eks_cluster_auth" "this" {
  name = aws_eks_cluster.eks_cluster.name
}

provider "helm" {
  kubernetes {
    host                   = aws_eks_cluster.eks_cluster.endpoint
    cluster_ca_certificate = base64decode(aws_eks_cluster.eks_cluster.certificate_authority[0].data)
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      args        = ["eks", "get-token", "--cluster-name", aws_eks_cluster.eks_cluster.name]
      command     = "aws"
    }
  }
}

provider "kubernetes" {
  host                   = aws_eks_cluster.eks_cluster.endpoint
  cluster_ca_certificate = base64decode(aws_eks_cluster.eks_cluster.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.this.token
}

provider "kubectl" {
  host                   = aws_eks_cluster.eks_cluster.endpoint
  cluster_ca_certificate = base64decode(aws_eks_cluster.eks_cluster.certificate_authority[0].data)
  load_config_file       = false
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    args        = ["eks", "get-token", "--cluster-name", aws_eks_cluster.eks_cluster.name]
    command     = "aws"
  }
  apply_retry_count = 3
}