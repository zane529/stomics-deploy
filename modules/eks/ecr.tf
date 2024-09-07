################################################################################
# Amazon ECR
################################################################################
resource "aws_ecr_repository" "ecr" {
  name                 = "${var.project_name}-ecr-${random_id.suffix.hex}/cromwell"
  image_tag_mutability = "MUTABLE"

#   image_scanning_configuration {
#     scan_on_push = true
#   }
}