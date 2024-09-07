# 输出 S3 桶名称
output "bucket_name" {
  description = "The S3 Bucket name"
  value       = aws_s3_bucket.s3.id
}

# 输出 S3 Pod 角色 ARN
output "s3_access_role_arn" {
  value = aws_iam_role.s3_access_role.arn
  description = "ARN of the IAM role for S3 access"
}

# 输出 S3 PVC
output "s3_pvc" {
  value = kubernetes_persistent_volume_claim.s3.metadata[0].name
  description = "The S3 PVC"
}