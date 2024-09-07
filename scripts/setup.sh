#!/bin/bash


echo "Update OS tools"
sudo yum update -y
echo "Install OS tools"
sudo yum -y install jq pip

#
# AWS cli v2 is now the default in cloud9
#
#echo "Uninstall AWS CLI v1"
#sudo /usr/local/bin/pip uninstall awscli -y 2&> /dev/null
#sudo pip uninstall awscli -y 2&> /dev/null
#echo "Install AWS CLI v2"
#curl --silent "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" > /dev/null
#unzip -qq awscliv2.zip
#sudo ./aws/install > /dev/null
#echo "alias aws='/usr/local/bin/aws'" >> ~/.bash_profile
#source ~/.bash_profile
#rm -f awscliv2.zip
#rm -rf aws

# setup for AWS cli
export ACCOUNT_ID=$(aws sts get-caller-identity --output text --query Account)
TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
export AWS_REGION=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" -s http://169.254.169.254/latest/meta-data/placement/region)
test -n "$AWS_REGION" && echo AWS_REGION is "$AWS_REGION" || echo "AWS_REGION is not set !!"
echo "export ACCOUNT_ID=${ACCOUNT_ID}" | tee -a ~/.bash_profile
echo "export AWS_REGION=${AWS_REGION}" | tee -a ~/.bash_profile


aws configure set default.region ${AWS_REGION}
aws configure get region

echo "Setup Terraform"
sudo dnf install -y yum-utils
sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/AmazonLinux/hashicorp.repo
sudo dnf install -y terraform
terraform version

echo "Setup Terraform cache"
if [ ! -f $HOME/.terraform.d/plugin-cache ]; then
  mkdir -p $HOME/.terraform.d/plugin-cache
  cp dot-terraform.rc $HOME/.terraformrc # 需要细化，可以直接写文件
fi

echo "Setup kubectl"
if [ ! $(which kubectl 2>/dev/null) ]; then
  echo "Install kubectl v1.31.0"
  curl --silent -LO https://dl.k8s.io/release/v1.31.0/bin/linux/amd64/kubectl >/dev/null
  chmod +x ./kubectl
  sudo mv ./kubectl /usr/local/bin/kubectl >/dev/null
  kubectl completion bash >>~/.bash_completion
fi

# if [ ! $(which eksctl 2>/dev/null) ]; then
#   echo "install eksctl"
#   curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp >/dev/null
#   sudo mv -v /tmp/eksctl /usr/local/bin >/dev/null
#   echo "eksctl completion"
#   eksctl completion bash >>~/.bash_completion
# fi

if [ ! $(which helm 2>/dev/null) ]; then
  echo "helm"
  wget -q https://get.helm.sh/helm-v3.11.3-linux-amd64.tar.gz >/dev/null
  tar -zxf helm-v3.11.3-linux-amd64.tar.gz
  sudo mv linux-amd64/helm /usr/local/bin/helm >/dev/null
  rm -rf helm-v3.11.3-linux-amd64.tar.gz linux-amd64
fi

# Update helm
# Add eks-charts 仓库
helm repo add eks https://aws.github.io/eks-charts
# Add Karpenter 仓库
helm repo add karpenter https://charts.karpenter.sh
helm repo update