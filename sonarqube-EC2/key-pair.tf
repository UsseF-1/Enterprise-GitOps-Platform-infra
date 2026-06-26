resource "aws_key_pair" "sonarqube_key" {
  key_name   = "sonarqube_key"
  public_key = file("sonarqube-key-GitOps-platform.pub")
}