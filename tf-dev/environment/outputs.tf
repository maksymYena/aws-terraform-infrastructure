output "bucket_name" {
  value = module.environment.bucket_name
}

output "dynamodb_name" {
  value = module.environment.dynamodb_name
}

output "subnet_ids" {
  value = module.environment.subnet_ids
}

output "vpc_id" {
  value = module.environment.vpc_id
}

output "region_name" {
  value = module.environment.region_name
}

output "sqs_queue_arn" {
  value = module.environment.sqs_queue_arn
}

output "ecr_repository_url" {
  value = module.environment.ecr_repository_url
}