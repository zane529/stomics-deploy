#!/bin/bash

# 设置环境变量
export AWS_PROFILE=your_aws_profile

# 选择环境
ENV=\$1
if [ -z "$ENV" ]; then
    echo "Please specify environment (dev or prod)"
    exit 1
fi

# 切换到正确的目录
cd "environments/$ENV"

# 初始化 Terraform
terraform init

# 创建执行计划
terraform plan -out=tfplan

# 应用更改
terraform apply tfplan

# 清理计划文件
rm tfplan
