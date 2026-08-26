output "bucket_name" {
  value = aws_s3_bucket.image_bucket.bucket
}

output "dynamodb_name" {
  value = aws_dynamodb_table.recognition_results.name
}

output "default_subnet_ids" {
  value = [
    aws_default_subnet.default_subnet_a.id,
    aws_default_subnet.default_subnet_b.id
  ]
}

output "default_vpc_id" {
  value = data.aws_vpc.default.id
}

output "default_region_name" {
  value = data.aws_region.current.region
}

output "sqs_queue_arn" {
  value = aws_sqs_queue.image_queue.arn
}