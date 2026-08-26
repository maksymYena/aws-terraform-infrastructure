variable "bucket_name" {
  type        = string
  description = "Name of the S3 bucket"
}

variable "dynamodb_name" {
  type        = string
  description = "Name of the DynamoDB table"
}

variable "subnet_ids" {
  type        = list(string)
  description = "List of subnet IDs"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID"
}

variable "region_name" {
  type        = string
  description = "AWS region name"
}

variable "ami_uri" {
  type        = string
  description = "Application image URI"
}

variable "application_port" {
  type        = number
  description = "Port used by the application"
  default     = 80
}

variable "sqs_queue_arn" {
  type        = string
  description = "ARN of the SQS queue used as Lambda event source"
}