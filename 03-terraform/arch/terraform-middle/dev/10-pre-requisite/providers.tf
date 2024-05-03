terraform {
  required_version = ">= 0.14.0"

  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = ">= 3.31"
    }
  }
}

provider "aws" {
  region    = var.context.aws_region
  profile   = var.context.aws_profile
  shared_credentials_files = [var.context.aws_credentials_file]
}