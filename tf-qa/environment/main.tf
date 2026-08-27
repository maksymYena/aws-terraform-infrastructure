module "environment" {
  source = "../../modules/tf-environment"

  environment         = var.environment
  vpc_cidr            = var.vpc_cidr
  public_subnet_cidrs = var.public_subnet_cidrs

  bucket_name = var.bucket_name
  sns_name    = var.sns_name
  sqs_name    = var.sqs_name
}