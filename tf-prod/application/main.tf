data "terraform_remote_state" "environment" {
  backend = "s3"

  config = {
    bucket  = "maksym-yena-terraform-state"
    key     = "prod/environment.tfstate"
    region  = "eu-central-1"
    profile = "terraform-dev"
  }
}

module "application" {
  source = "../../modules/tf-application"

  environment = var.environment

  bucket_name   = data.terraform_remote_state.environment.outputs.bucket_name
  dynamodb_name = data.terraform_remote_state.environment.outputs.dynamodb_name

  subnet_ids = data.terraform_remote_state.environment.outputs.subnet_ids
  vpc_id     = data.terraform_remote_state.environment.outputs.vpc_id

  region_name   = data.terraform_remote_state.environment.outputs.region_name
  sqs_queue_arn = data.terraform_remote_state.environment.outputs.sqs_queue_arn

  ami_uri = "${data.terraform_remote_state.environment.outputs.ecr_repository_url}:latest"
}