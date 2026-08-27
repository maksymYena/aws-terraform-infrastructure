variable "environment" {
  type = string
}

variable "vpc_cidr" {
  type = string
}

variable "public_subnet_cidrs" {
  type = list(string)
}

variable "bucket_name" {
  type = string
}

variable "sns_name" {
  type = string
}

variable "sqs_name" {
  type = string
}