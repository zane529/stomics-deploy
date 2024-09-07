################################################################################
# Amazon ECR
################################################################################
resource "aws_ecr_repository" "ecr" {
  name                 = "${var.project_name}-ecr-${random_id.suffix.hex}/cromwell"
  image_tag_mutability = "MUTABLE"

#   image_scanning_configuration {
#     scan_on_push = true
#   }
  depends_on = [null_resource.delete_ecr_images]
}

resource "null_resource" "delete_ecr_images" {
  triggers = {
    ecr_repository_name = aws_ecr_repository.ecr.name
  }

  # 这个 provisioner 只在资源被销毁时执行
  provisioner "local-exec" {
    when    = destroy
    command = <<EOF
      # 获取所有镜像标签
      IMAGES_TO_DELETE=$$(aws ecr list-images --repository-name ${self.triggers.ecr_repository_name} --query 'imageIds[*]' --output json)
      
      # 如果有镜像，则删除它们
      if [ "$${IMAGES_TO_DELETE}" != "[]" ]; then
        aws ecr batch-delete-image --repository-name ${self.triggers.ecr_repository_name} --image-ids "$${IMAGES_TO_DELETE}"
      fi
    EOF
  }
}