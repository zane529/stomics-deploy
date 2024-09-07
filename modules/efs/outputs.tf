# 输出 S3 PVC
output "efs_pvc" {
  value = kubernetes_persistent_volume_claim.efs.metadata[0].name
  description = "The S3 PVC"
}