provider "aws" {
  region = "us-east-1"
}

terraform {
  backend "s3" {
    bucket         	   = "p4-devops-terraform-state"
    key                = "state/terraform.tfstate"
    region         	   = "us-east-1"
    encrypt        	   = true
  }
}

