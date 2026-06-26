# output "instance_id" {
#     description = "AMI ID of Ubuntu instance"
#     value       = data.aws_ami.amiID.id
# }

output "sonarqubePublicIP" {
  description = "AMI ID of Ubuntu instance"
  value       = aws_instance.sonarqube.public_ip
}

output "sonarqubePrivateIP" {
  description = "AMI ID of Ubuntu instance"
  value       = aws_instance.sonarqube.private_ip
}

# output "public_ip" {
#     description = "Public IP of SonarQube EC2"
#     value       = aws_instance.sonarqube.public_ip
# }

# output "private_ip" {
#     description = "Private IP of SonarQube EC2"
#     value       = aws_instance.sonarqube.private_ip
# }

output "instance_id" {
  description = "EC2 Instance ID"
  value       = aws_instance.sonarqube.id
}