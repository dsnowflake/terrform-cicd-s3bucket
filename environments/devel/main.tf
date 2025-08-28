# This file provisions the development environment.

# Configure the AWS provider.
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

# Call the app-infra module for the 'devel' environment.
module "devel_app" {
  source = "../../modules/app-infra"
  env    = "devel"
}