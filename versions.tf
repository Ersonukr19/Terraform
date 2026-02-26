terraform {
  required_version = ">= 1.6.0"

  backend "s3" {
    bucket         = "company-terraform-state"
    key            = "uat/aws/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
