echo "kubectl"
kubectl version

rm -f ~/.kube/config
aws eks update-kubeconfig --name $1