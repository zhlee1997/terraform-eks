terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      # aws provider > 5.34 for authentication_mode
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region     = var.aws_region
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}
