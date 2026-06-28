terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.95"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = var.region
}
