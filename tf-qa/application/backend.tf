terraform {
  backend "s3" {
    bucket  = "maksym-yena-terraform-state"
    key     = "qa/application.tfstate"
    region  = "eu-central-1"
    profile = "terraform-dev"
    encrypt = true
  }
}