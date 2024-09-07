#!/bin/bash

# 配置 kubectl
rm -rf ~/.kube
# aws eks update-kubeconfig --name $CLUSTER_NAME

# 启动 Cromwell
exec java -jar /app/cromwell.jar server