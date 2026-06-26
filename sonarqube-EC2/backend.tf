terraform {
    backend "s3" {
        bucket  = "sonarqube-bucket-gitops-project"
        key     = "dev/terraform.tfstate"
        region  = "us-east-1"
        encrypt = true
        # dynamodb_table = "terraform-locks"  #COST
    }
}