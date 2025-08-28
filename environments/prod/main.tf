# This file provisions the production environment.

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

# Call the app-infra module for the 'prod' environment.
module "prod_app" {
  source = "../../modules/app-infra"
  env    = "prod"
}