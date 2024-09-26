# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0

################################################################################
# 创建 Prometheus Server, prometheus-server 作为服务名称，这是 Prometheus Helm Chart 默认创建的服务名称。
################################################################################
resource "helm_release" "prometheus" {
  timeout = 600
  name       = "prometheus"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "prometheus"
  namespace  = "monitoring"
  create_namespace = true

  set {
    name  = "server.global.scrape_interval"
    value = "15s"
  }

  set {
    name  = "server.global.evaluation_interval"
    value = "15s"
  }
  set {
    name  = "server.persistentVolume.storageClass"
    value = "gp2"
  }
  set {
    name  = "server.persistentVolume.size"
    value = "200Gi"
  }

  # 禁用 Alertmanager
  set {
    name  = "alertmanager.enabled"
    value = "false"
  }
  # 禁用 Pushgateway
  set {
    name  = "pushgateway.enabled"
    value = "false"
  }
}

################################################################################
# 为 Prometheus 创建 Ingress 资源
################################################################################
# resource "kubernetes_ingress_v1" "prometheus" {

#   depends_on = [helm_release.prometheus]

#   metadata {
#     name      = "prometheus-ingress"
#     namespace = kubernetes_namespace.monitoring.metadata[0].name
#     annotations = {
#       "kubernetes.io/ingress.class"               = "alb"
#       "alb.ingress.kubernetes.io/scheme"          = "internet-facing" # 可能要改为内网的 ALB
#       "alb.ingress.kubernetes.io/target-type"     = "ip"
#       "alb.ingress.kubernetes.io/healthcheck-path" = "/-/healthy"
#     }
#   }

#   spec {
#     rule {
#       http {
#         path {
#           path = "/*"
#           backend {
#             service {
#               name = "prometheus-server"
#               port {
#                 number = 80
#               }
#             }
#           }
#         }
#       }
#     }
#   }
# }