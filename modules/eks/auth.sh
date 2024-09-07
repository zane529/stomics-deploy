echo "kubectl"
kubectl version

rm -f ~/.kube/config
aws eks update-kubeconfig --name $1

# Update helm
# Add eks-charts 仓库
helm repo add eks https://aws.github.io/eks-charts
# Add Karpenter 仓库
helm repo add karpenter https://charts.karpenter.sh
helm repo update