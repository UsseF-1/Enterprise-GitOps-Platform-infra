terraform {
    backend "s3" {
        bucket  = "eks-gitops-platform"
        key     = "dev/terraform.tfstate"
        region  = "us-east-1"
        encrypt = true
        # dynamodb_table = "terraform-locks"  #COST
    }
}