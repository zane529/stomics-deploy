################################################################################
# 部署 2048 小游戏，测试 AWS Load Balance
################################################################################

# resource "kubectl_manifest" "app-2048" {
  
#   yaml_body = <<-YAML
#   ---
#   apiVersion: apps/v1
#   kind: Deployment
#   metadata:
#     namespace: default
#     name: deployment-app-2048
#   spec:
#     selector:
#       matchLabels:
#         app.kubernetes.io/name: app-2048
#     replicas: 2
#     template:
#       metadata:
#         labels:
#           app.kubernetes.io/name: app-2048
#       spec:
#         containers:
#         - image: public.ecr.aws/l6m2t8p7/docker-2048:latest
#           imagePullPolicy: Always
#           name: app-2048
#           ports:
#           - containerPort: 80
#   ---
#   apiVersion: v1
#   kind: Service
#   metadata:
#     namespace: default
#     name: service-2048
#   spec:
#     ports:
#       - port: 80
#         targetPort: 80
#         protocol: TCP
#     type: NodePort
#     selector:
#       app.kubernetes.io/name: app-2048
#   ---
#   apiVersion: networking.k8s.io/v1
#   kind: Ingress
#   metadata:
#     namespace: default
#     name: ingress-2048
#     annotations:
#       alb.ingress.kubernetes.io/scheme: internet-facing
#       alb.ingress.kubernetes.io/target-type: ip
#   spec:
#     ingressClassName: alb
#     rules:
#       - http:
#           paths:
#           - path: /
#             pathType: Prefix
#             backend:
#               service:
#                 name: service-2048
#                 port:
#                   number: 80
# YAML
# }

# resource "kubectl_manifest" "app-efs" {
#   yaml_body = <<-YAML
#   apiVersion: v1
#   kind: Pod
#   metadata:
#     name: app-efs
#   spec:
#     containers:
#     - name: app
#       image: nginx
#       volumeMounts:
#       - name: persistent-storage
#         mountPath: /data
#     volumes:
#     - name: persistent-storage
#       persistentVolumeClaim:
#         claimName: efs-pvc
#   YAML
# }


################################################################################
# 部署 S3 测试程序
################################################################################
resource "kubernetes_job" "s3_app" {
  metadata {
    name = "s3-app"
  }

  spec {
    template {
      metadata {
        name = "s3-app"
      }

      spec {
        container {
          name    = "app"
          image   = "centos"
          command = ["/bin/sh", "-c"]
          args    = ["echo 'Hello from the container!' >> /data/pod-write-to-s3-$(date -u +%Y-%m-%d_%H-%M-%S).txt"]

          volume_mount {
            name       = "persistent-storage"
            mount_path = "/data"
          }
        }

        volume {
          name = "persistent-storage"
          persistent_volume_claim {
            claim_name = var.s3_pvc
          }
        }

        restart_policy = "Never"
      }
    }

    backoff_limit = 4
  }
}

