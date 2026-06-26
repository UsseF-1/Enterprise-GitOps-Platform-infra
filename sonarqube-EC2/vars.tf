variable "region" {
  description = "AWS region for all resources"
  default     = "us-east-1"
}

variable "instance_type" {
  default = "t3.medium"
}

variable "sonarqube_ami" {
  default = "ubuntu"
}

variable "webuser" {
  default = "ubuntu"
}