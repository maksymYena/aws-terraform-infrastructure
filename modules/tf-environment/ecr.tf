resource "aws_ecr_repository" "image_recognition" {
  name = "image-recognition-${var.environment}"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Environment = var.environment
    Component   = "container-registry"
  }
}