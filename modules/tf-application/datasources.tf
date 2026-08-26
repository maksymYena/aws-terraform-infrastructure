data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/lambda/index.py"
  output_path = "${path.module}/lambda_function_payload.zip"
}

data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = [
      "sts:AssumeRole"
    ]
  }
}

data "aws_iam_policy_document" "lambda_permissions" {
  statement {
    effect = "Allow"

    actions = [
      "sqs:DeleteMessage",
      "sqs:GetQueueAttributes",
      "sqs:ReceiveMessage"
    ]

    resources = [
      var.sqs_queue_arn
    ]
  }

  statement {
    effect = "Allow"

    actions = [
      "dynamodb:GetItem",
      "dynamodb:PutItem",
      "dynamodb:UpdateItem",
      "dynamodb:BatchWriteItem",
      "dynamodb:BatchGetItem"
    ]

    resources = [
      "arn:aws:dynamodb:${var.region_name}:${data.aws_caller_identity.current.account_id}:table/${var.dynamodb_name}",
      "arn:aws:dynamodb:${var.region_name}:${data.aws_caller_identity.current.account_id}:table/${var.dynamodb_name}/index/*"
    ]
  }

  statement {
    effect = "Allow"

    actions = [
      "rekognition:DetectLabels"
    ]

    resources = ["*"]
  }

  statement {
    effect = "Allow"

    actions = [
      "s3:GetObject",
      "s3:ListBucket"
    ]

    resources = [
      "arn:aws:s3:::${var.bucket_name}",
      "arn:aws:s3:::${var.bucket_name}/*"
    ]
  }

  statement {
    effect = "Allow"

    actions = [
      "logs:CreateLogGroup"
    ]

    resources = [
      "arn:aws:logs:${var.region_name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/image-recognition-lambda"
    ]
  }

  statement {
    effect = "Allow"

    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]

    resources = [
      "arn:aws:logs:${var.region_name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/image-recognition-lambda:*"
    ]
  }
}

data "aws_iam_policy_document" "ecs_execution_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }

    actions = [
      "sts:AssumeRole"
    ]
  }
}

data "aws_iam_policy" "ecs_execution_policy" {
  name = "AmazonECSTaskExecutionRolePolicy"
}

data "aws_iam_policy" "ecs_s3_access" {
  name = "AmazonS3FullAccess"
}

data "aws_iam_policy" "ecs_dynamodb_access" {
  name = "AmazonDynamoDBFullAccess"
}