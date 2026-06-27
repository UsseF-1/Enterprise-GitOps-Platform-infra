output "ecr_app_url" {
  description = "ECR URL for app image"
  value       = aws_ecr_repository.vprofile_app_image.repository_url
}
output "ecr_name" {
  description = "ECR name for app image"
  value       = aws_ecr_repository.vprofile_app_image.name
}