output "bucket_name" {
  value = aws_s3_bucket.image_bucket.bucket
}

output "dynamodb_name" {
  value = aws_dynamodb_table.recognition_results.name
}

output "subnet_ids" {
  value = aws_subnet.public[*].id
}

output "vpc_id" {
  value = aws_vpc.environment_vpc.id
}

output "region_name" {
  value = data.aws_region.current.region
}

output "sqs_queue_arn" {
  value = aws_sqs_queue.image_queue.arn
}

output "ecr_repository_url" {
  value = aws_ecr_repository.image_recognition.repository_url
}