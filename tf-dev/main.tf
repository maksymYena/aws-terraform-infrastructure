module "environment" {
  source = "../modules/tf-environment"

  bucket_name = "maksym-yena-image-bucket-dev"
  sns_name    = "image-notification-dev"
  sqs_name    = "image-queue-dev"
}

module "application" {
  source = "../modules/tf-application"

  bucket_name   = module.environment.bucket_name
  dynamodb_name = module.environment.dynamodb_name
  subnet_ids    = module.environment.default_subnet_ids
  vpc_id        = module.environment.default_vpc_id
  region_name   = module.environment.default_region_name
  sqs_queue_arn = module.environment.sqs_queue_arn

  ami_uri = "888840134536.dkr.ecr.eu-central-1.amazonaws.com/image-recognition:latest"
}