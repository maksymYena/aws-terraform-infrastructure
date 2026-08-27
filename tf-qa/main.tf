module "environment" {
  source = "../modules/tf-environment"

  environment         = var.environment
  vpc_cidr            = var.vpc_cidr
  public_subnet_cidrs = var.public_subnet_cidrs

  bucket_name = var.bucket_name
  sns_name    = var.sns_name
  sqs_name    = var.sqs_name
}

module "application" {
  source = "../modules/tf-application"

  bucket_name   = module.environment.bucket_name
  dynamodb_name = module.environment.dynamodb_name

  subnet_ids = module.environment.subnet_ids
  vpc_id     = module.environment.vpc_id

  region_name   = module.environment.region_name
  sqs_queue_arn = module.environment.sqs_queue_arn

  ami_uri = "${module.environment.ecr_repository_url}:latest"

  environment = var.environment
}