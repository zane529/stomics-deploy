################################################################################
# Amazon ECR
################################################################################
resource "aws_ecr_repository" "ecr" {
  name                 = "${var.eks_name}-ecr/cromwell"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "null_resource" "delete_ecr_images" {
  triggers = {
    ecr_repository_name = aws_ecr_repository.ecr.name
  }

  # 这个 provisioner 只在资源被销毁时执行
  provisioner "local-exec" {
    when    = destroy
    command = <<EOF
      # 获取所有镜像标签
      IMAGES_TO_DELETE=$(aws ecr list-images --repository-name ${self.triggers.ecr_repository_name} --query 'imageIds[*]' --output json)
      
      # 如果有镜像，则删除它们
      if [ "$${IMAGES_TO_DELETE}" != "[]" ]; then
        aws ecr batch-delete-image --repository-name ${self.triggers.ecr_repository_name} --image-ids "$${IMAGES_TO_DELETE}"
      fi
    EOF
  }
}

################################################################################
# 本地变量
################################################################################
locals {
  cromwell_sa = "cromwell-sa"
  cromwell_image_url = "${aws_ecr_repository.ecr.repository_url}:latest"
}

################################################################################
# 构建 Cromwell 镜像并且推送到 Amazon ECR
################################################################################
resource "null_resource" "docker_build_and_push" {

  depends_on = [ aws_ecr_repository.ecr ]

  # triggers = {
  #   cluster_name = var.eks_name
  #   dockerfile_hash = filemd5("${path.module}/dockerfile/Dockerfile")
  #   start_sh_hash   = filemd5("${path.module}/dockerfile/start.sh")
  # }

  provisioner "local-exec" {
    on_failure  = fail
    when        = create
    interpreter = ["/bin/bash", "-c"]
    command = <<EOF
      aws ecr get-login-password --region ${var.aws_region} | docker login --username AWS --password-stdin ${aws_ecr_repository.ecr.repository_url}
      docker build -t ${local.cromwell_image_url} ${path.module}/dockerfile
      docker push ${local.cromwell_image_url}
      echo "************************************************************************************"
    EOF
   
  }
}

################################################################################
# 创建 Cromwell Pod 对应的 Role
################################################################################
resource "aws_iam_role" "cromwell_role" {
  name = "${var.eks_name}-cromwell-role"

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
            "${replace(var.eks_cluster_oidc_issuer, "https://", "")}:sub": "system:serviceaccount:${var.k8s_namespace}:${local.cromwell_sa}"
          }
        }
      },
    ]
  })
}

################################################################################
# 附加 Cromwell Role 的策略
################################################################################
resource "aws_iam_role_policy_attachment" "cromwell_eks_policy" {
  depends_on = [ aws_iam_role.cromwell_role ]
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.cromwell_role.name
}

resource "aws_iam_role_policy_attachment" "cromwell_ecr_policy" {
  depends_on = [ aws_iam_role.cromwell_role ]
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.cromwell_role.name
}

resource "aws_iam_role_policy_attachment" "cromwell_s3_policy" {
  depends_on = [ aws_iam_role.cromwell_role ]
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
  role       = aws_iam_role.cromwell_role.name
}

################################################################################
# 创建 Cromwell service account
################################################################################
resource "kubernetes_service_account" "cromwell_sa" {
  depends_on = [ aws_iam_role.cromwell_role ]
  metadata {
    name      = local.cromwell_sa
    namespace = var.k8s_namespace
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.cromwell_role.arn
    }
  }
}

################################################################################
# Cromwell service account 绑定 cluster-admin ClusterRole
################################################################################
resource "kubernetes_cluster_role_binding" "cromwell_sa_admin_binding" {
  depends_on = [ kubernetes_service_account.cromwell_sa ]
  metadata {
    name = "cromwell_sa_admin_binding"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "cluster-admin"
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.cromwell_sa.metadata[0].name
    namespace = kubernetes_service_account.cromwell_sa.metadata[0].namespace
  }
}

################################################################################
# 部署 Cromwell 应用程序
################################################################################
resource "kubernetes_deployment" "cromwell" {
  depends_on = [ kubernetes_cluster_role_binding.cromwell_sa_admin_binding, null_resource.docker_build_and_push ]
  metadata {
    name = "cromwell"
    labels = {
      app = "cromwell"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "cromwell"
      }
    }

    template {
      metadata {
        labels = {
          app = "cromwell"
        }
      }

      spec {
        service_account_name = local.cromwell_sa
        container {
          image = local.cromwell_image_url
          name  = "cromwell"

          env {
            name  = "AWS_REGION"
            value = var.aws_region
          }

          env {
            name  = "CLUSTER_NAME"
            value = var.eks_name
          }

          env {
            name  = "KUBE_CONFIG_PATH"
            value = "/root/.kube/config"
          }

          port {
            container_port = 8000
          }

          volume_mount {
            name       = "efs-storage"
            mount_path = "/efs-data"
          }

          volume_mount {
            name       = "s3-storage"
            mount_path = "/s3-data"
          }

          resources {
            limits = {
              cpu    = "4"
              memory = "8Gi"
            }
            requests = {
              cpu    = "2"
              memory = "4Gi"
            }
          }
        }

        volume {
          name = "efs-storage"
          persistent_volume_claim {
            claim_name = var.efs_pvc
          }
        }

        volume {
          name = "s3-storage"
          persistent_volume_claim {
            claim_name = var.s3_pvc
          }
        }

      }
    }
  }
}

resource "kubernetes_service" "cromwell" {
  metadata {
    name = "cromwell"
  }
  spec {
    selector = {
      app = kubernetes_deployment.cromwell.spec.0.template.0.metadata.0.labels.app
    }
    port {
      port        = 80
      target_port = 8000
    }
    type = "NodePort"
  }
}

# resource "kubernetes_ingress_v1" "cromwell" {

#   metadata {
#     name = "cromwell"
#     annotations = {
#       "kubernetes.io/ingress.class"                = "alb"
#       "alb.ingress.kubernetes.io/scheme"           = "internet-facing"
#       "alb.ingress.kubernetes.io/target-type"      = "ip"
#       "alb.ingress.kubernetes.io/healthcheck-path" = "/engine/v1/version"
#     }
#   }

#   spec {
#     rule {
#       http {
#         path {
#           path = "/*"
#           backend {
#             service {
#               name = kubernetes_service.cromwell.metadata.0.name
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

################################################################################
# 当执行 terraform destroy 销毁时先删除 AWS 上的 ALB 资源
################################################################################
# resource "null_resource" "delete_alb" {
#   triggers = {
#     ingress_name = kubernetes_ingress_v1.cromwell.metadata[0].name
#     namespace    = kubernetes_ingress_v1.cromwell.metadata[0].namespace
#   }

#   provisioner "local-exec" {
#     when    = destroy
#     command = <<-EOT
#       #!/bin/bash
#       set -e

#       echo "Deleting Ingress ${self.triggers.ingress_name} in namespace ${self.triggers.namespace}"
#       kubectl delete ingress ${self.triggers.ingress_name} -n ${self.triggers.namespace} --ignore-not-found

#       echo "Waiting for ALB to be deleted..."
#       while true; do
#         ALB_NAME=$(aws elbv2 describe-load-balancers --query "LoadBalancers[?contains(DNSName, '${kubernetes_ingress_v1.cromwell.status[0].load_balancer[0].ingress[0].hostname}')].LoadBalancerArn" --output text)
#         if [ -z "$ALB_NAME" ]; then
#           echo "ALB has been deleted."
#           break
#         fi
#         echo "ALB still exists, waiting..."
#         sleep 10
#       done
#     EOT
#     interpreter = ["/bin/bash", "-c"]
#   }
#   depends_on = [kubernetes_ingress_v1.cromwell]
# }


