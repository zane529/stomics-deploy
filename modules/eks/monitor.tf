# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0

################################################################################
# 创建 monitoring 命名空间
################################################################################
resource "kubernetes_namespace" "monitoring" {
  depends_on = [ aws_eks_node_group.eks_node_group, helm_release.lb ]
  metadata {
    name = "monitoring"
  }
}

################################################################################
# 创建一个 Ingress 类
################################################################################
# resource "kubernetes_ingress_class_v1" "alb" {
#   metadata {
#     name = "alb"
#   }

#   spec {
#     controller = "ingress.k8s.aws/alb"
#   }
# }

################################################################################
# 创建 Prometheus Server, prometheus-server 作为服务名称，这是 Prometheus Helm Chart 默认创建的服务名称。
################################################################################
resource "helm_release" "prometheus" {
  name       = "prometheus"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "prometheus"
  namespace  = kubernetes_namespace.monitoring.metadata[0].name

  depends_on = [ aws_eks_node_group.eks_node_group, helm_release.lb ]

}

################################################################################
# 为 Prometheus 创建 Ingress 资源
################################################################################
resource "kubernetes_ingress_v1" "prometheus" {

  depends_on = [helm_release.prometheus]

  metadata {
    name      = "prometheus-ingress"
    namespace = kubernetes_namespace.monitoring.metadata[0].name
    annotations = {
      "kubernetes.io/ingress.class"               = "alb"
      "alb.ingress.kubernetes.io/scheme"          = "internet-facing" # 可能要改为内网的 ALB
      "alb.ingress.kubernetes.io/target-type"     = "ip"
      "alb.ingress.kubernetes.io/healthcheck-path" = "/-/healthy"
    }
  }

  spec {
    rule {
      http {
        path {
          path = "/*"
          backend {
            service {
              name = "prometheus-server"
              port {
                number = 80
              }
            }
          }
        }
      }
    }
  }
}

################################################################################
# 创建 Grafana Server
################################################################################
resource "helm_release" "grafana" {
  name       = "grafana"
  repository = "https://grafana.github.io/helm-charts"
  chart      = "grafana"
  namespace  = kubernetes_namespace.monitoring.metadata[0].name

  depends_on = [ aws_eks_node_group.eks_node_group, helm_release.lb ]

}

################################################################################
# 为 Grafana 创建 Ingress 资源
################################################################################
resource "kubernetes_ingress_v1" "grafana" {
  depends_on = [ helm_release.grafana ]
  metadata {
    name      = "grafana-ingress"
    namespace = kubernetes_namespace.monitoring.metadata[0].name
    annotations = {
      "kubernetes.io/ingress.class"               = "alb"
      "alb.ingress.kubernetes.io/scheme"          = "internet-facing" # 可能要改为内网的 ALB
      "alb.ingress.kubernetes.io/target-type"     = "ip"
      "alb.ingress.kubernetes.io/healthcheck-path" = "/api/health"
    }
  }

  spec {
    rule {
      http {
        path {
          path = "/*"
          backend {
            service {
              name = "grafana"
              port {
                number = 80
              }
            }
          }
        }
      }
    }
  }
}




