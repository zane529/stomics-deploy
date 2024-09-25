#!/bin/bash
aws ecr get-login-password --region ${aws_region} | docker login --username AWS --password-stdin ${ecr_repository_url}
docker build -t ${cromwell_image_url} ${dockerfile_path}
docker push ${cromwell_image_url}