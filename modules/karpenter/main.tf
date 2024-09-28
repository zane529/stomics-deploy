# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0

################################################################################
# 为 Karpenter 创建 IAM 角色
################################################################################
module "karpenter_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"

  role_name                          = "${var.eks_name}-karpenter-controller"
  attach_karpenter_controller_policy = true

  karpenter_tag_key               = "karpenter.sh/discovery"
  karpenter_controller_cluster_id = var.eks_name
  karpenter_controller_node_iam_role_arns = [
    var.eks_node_group_role_arn
  ]

  oidc_providers = {
    ex = {
      provider_arn               = replace(var.eks_cluster_oidc_issuer, "https://", "arn:aws:iam::${var.aws_account_id}:oidc-provider/")
      namespace_service_accounts = ["karpenter:karpenter"]
    }
  }
}

################################################################################
# 创建 Karpenter 所需的 EC2 Spot 服务相关角色
################################################################################
resource "aws_iam_instance_profile" "karpenter" {
  name = "KarpenterNodeInstanceProfile-${var.eks_name}"
  role = var.eks_node_group_role_name
}

################################################################################
# 创建 Karpenter
################################################################################
resource "helm_release" "karpenter" {
  depends_on = [ aws_iam_instance_profile.karpenter ]
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
    value = var.eks_name
  }

  set {
    name  = "clusterEndpoint"
    value = var.eks_endpoint
  }

  set {
    name  = "aws.defaultInstanceProfile"
    value = aws_iam_instance_profile.karpenter.name
  }
}

################################################################################
# 创建 Karpenter 默认的 Provisioner
################################################################################

terraform {
  required_providers {
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.14.0"
    }
  }
}

resource "kubectl_manifest" "karpenter_default_provisioner" {
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
    labels:
      cpu-node: "true"
    provider:
      subnetSelector:
        Name: "${var.eks_name}-private*"
      securityGroupSelector:
        "aws:eks:cluster-name": ${var.eks_name}
      tags:
        "karpenter.sh/discovery": ${var.eks_name}
    ttlSecondsAfterEmpty: 30
  YAML
  depends_on = [ helm_release.karpenter ]
}


################################################################################
# 安装 GPU Driver
################################################################################
resource "kubectl_manifest" "karpenter_nvidia_device_plugin" {
  yaml_body = <<-YAML
    apiVersion: apps/v1
    kind: DaemonSet
    metadata:
      name: nvidia-device-plugin-daemonset
      namespace: kube-system
    spec:
      selector:
        matchLabels:
          name: nvidia-device-plugin-ds
      updateStrategy:
        type: RollingUpdate
      template:
        metadata:
          labels:
            name: nvidia-device-plugin-ds
        spec:
          tolerations:
          - key: nvidia.com/gpu
            operator: Exists
            effect: NoSchedule
          priorityClassName: "system-node-critical"
          containers:
          - image: nvcr.io/nvidia/k8s-device-plugin:v0.14.5
            name: nvidia-device-plugin-ctr
            env:
              - name: FAIL_ON_INIT_ERROR
                value: "false"
            securityContext:
              allowPrivilegeEscalation: false
              capabilities:
                drop: ["ALL"]
            volumeMounts:
            - name: device-plugin
              mountPath: /var/lib/kubelet/device-plugins
          volumes:
          - name: device-plugin
            hostPath:
              path: /var/lib/kubelet/device-plugins
    YAML
  depends_on = [ helm_release.karpenter ]
}

################################################################################
# 创建 Karpenter GPU 的 Provisioner
################################################################################

resource "kubectl_manifest" "karpenter_gpu_provisioner" {
  yaml_body = <<-YAML
  apiVersion: karpenter.sh/v1alpha5
  kind: Provisioner
  metadata:
    name: "gpu-provisioner"
  spec:
    requirements:
      - key: karpenter.sh/capacity-type
        operator: In
        values: ["on-demand"]
      - key: node.kubernetes.io/instance-type
        operator: In
        values: ["g4dn.2xlarge", "g5.2xlarge"]
    limits:
      resources:
        cpu: 1000
        memory: 4000Gi
        nvidia.com/gpu: 100
    labels:
      gpu-node: "true"
    provider:
      subnetSelector:
        Name: "${var.eks_name}-private*"
      securityGroupSelector:
        "aws:eks:cluster-name": ${var.eks_name}
      tags:
        "karpenter.sh/discovery": ${var.eks_name}
    ttlSecondsAfterEmpty: 30
  YAML
  depends_on = [ helm_release.karpenter ]
}
