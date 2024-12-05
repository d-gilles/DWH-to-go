terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }

  }
}

provider "aws" {
    region                      = var.aws_region
    profile                     = var.aws_terraform_user
    shared_config_files         = ["~/.aws/config_terraform"]
    shared_credentials_files    = ["~/.aws/cred_terraform"]
}





