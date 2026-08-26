variable "bucket_name" {
  type        = string
  description = "Name of the S3 bucket to create"
  default     = "s3-image-bucket"
}

variable "sns_name" {
  type        = string
  description = "Name of the SNS topic"
  default     = "image-notification"
}

variable "sqs_name" {
  type        = string
  description = "Name of the SQS queue"
  default     = "image-queue"
}