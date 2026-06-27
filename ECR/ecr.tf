resource "aws_ecr_repository" "vprofile_app_image" {
  name                 = "vprofile_app_image"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  force_delete = false

  lifecycle {
    prevent_destroy = true
  }

  tags = {
    Name = "vprofile-app-image"
  }
}