terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }

    archive = {
      source = "hashicorp/archive"
    }
  }
}

provider "aws" {
  region  = "eu-central-1"
  profile = "terraform-dev"
}