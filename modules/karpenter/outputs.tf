# 输出 Karpenter role
output "karpenter_iam_role_name" {
  value = module.karpenter_irsa.iam_role_name
}