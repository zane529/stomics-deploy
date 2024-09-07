# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0

################################################################################
# 为 Karpenter 创建 IAM 角色
################################################################################
module "karpenter_irsa" {
  depends_on = [ aws_iam_openid_connect_provider.eks_oidc, aws_iam_role.eks_node_group_role, aws_eks_node_group.eks_node_group ]
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"

  role_name                          = "${aws_eks_cluster.eks_cluster.name}-karpenter-controller"
  attach_karpenter_controller_policy = true

  karpenter_tag_key               = "karpenter.sh/discovery"
  karpenter_controller_cluster_id = aws_eks_cluster.eks_cluster.name
  karpenter_controller_node_iam_role_arns = [
    aws_iam_role.eks_node_group_role.arn
  ]

  oidc_providers = {
    ex = {
      provider_arn               = aws_iam_openid_connect_provider.eks_oidc.arn
      namespace_service_accounts = ["karpenter:karpenter"]
    }
  }
}

################################################################################
# 创建 Karpenter 所需的 EC2 Spot 服务相关角色
################################################################################
resource "aws_iam_instance_profile" "karpenter" {
  depends_on = [ aws_iam_role.eks_node_group_role, aws_eks_node_group.eks_node_group ]
  name = "KarpenterNodeInstanceProfile-${aws_eks_cluster.eks_cluster.name}"
  role = aws_iam_role.eks_node_group_role.name
}

################################################################################
# 创建 Karpenter
################################################################################
resource "helm_release" "karpenter" {
  depends_on = [ aws_eks_node_group.eks_node_group ]
  namespace        = "karpenter"
  create_namespace = true

  name       = "karpenter"
  repository = "https://charts.karpenter.sh"
  chart      = "karpenter"
  version    = var.karpenter_version

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = module.karpenter_irsa.iam_role_arn
  }

  set {
    name  = "clusterName"
    value = aws_eks_cluster.eks_cluster.name
  }

  set {
    name  = "clusterEndpoint"
    value = aws_eks_cluster.eks_cluster.endpoint
  }

  set {
    name  = "aws.defaultInstanceProfile"
    value = aws_iam_instance_profile.karpenter.name
  }
}

################################################################################
# 创建 Karpenter 默认的 Provisioner
################################################################################



resource "kubectl_manifest" "karpenter_provisioner" {
  yaml_body = <<-YAML
  apiVersion: karpenter.sh/v1alpha5
  kind: Provisioner
  metadata:
    name: "default"
  spec:
    requirements:
      - key: karpenter.sh/capacity-type
        operator: In
        values: ["on-demand"]
      - key: "karpenter.k8s.aws/instance-category"
        operator: In
        values: ["t", "c", "m"]
      - key: karpenter.k8s.aws/instance-family
        operator: In
        values: ["t3", "c5a", "c6i", "m6i"]
      - key: "karpenter.k8s.aws/instance-cpu"
        operator: In
        values: ["1", "2", "4", "8", "16", "32", "64", "96"]
    limits:
      resources:
        cpu: 1000
    provider:
      subnetSelector:
        Name: "${var.project_name}-private*"
      securityGroupSelector:
        "aws:eks:cluster-name": ${aws_eks_cluster.eks_cluster.name}
      tags:
        "karpenter.sh/discovery": ${aws_eks_cluster.eks_cluster.name}
    ttlSecondsAfterEmpty: 30
  YAML
  depends_on = [
    helm_release.karpenter, aws_eks_node_group.eks_node_group
  ]
}