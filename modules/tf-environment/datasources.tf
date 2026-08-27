data "aws_iam_policy_document" "image_bucket_policy" {
  statement {
    sid    = "AllowECSPutObjects"
    effect = "Allow"

    principals {
      type = "Service"
      identifiers = [
        "ecs.amazonaws.com",
        "ecs-tasks.amazonaws.com"
      ]
    }

    actions = [
      "s3:PutObject"
    ]

    resources = [
      "${aws_s3_bucket.image_bucket.arn}/*"
    ]
  }

  statement {
    sid    = "AllowLambdaListBucket"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = [
      "s3:ListBucket"
    ]

    resources = [
      aws_s3_bucket.image_bucket.arn
    ]
  }

  statement {
    sid    = "AllowLambdaGetObjects"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = [
      "s3:GetObject"
    ]

    resources = [
      "${aws_s3_bucket.image_bucket.arn}/*"
    ]
  }

  statement {
    sid    = "DenyInsecureTransport"
    effect = "Deny"

    actions = [
      "s3:*"
    ]

    resources = [
      "arn:aws:s3:::${var.bucket_name}",
      "arn:aws:s3:::${var.bucket_name}/*"
    ]

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}


data "aws_iam_policy_document" "sns_topic_policy" {
  statement {
    sid    = "AllowS3Publish"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["s3.amazonaws.com"]
    }

    actions = [
      "SNS:Publish"
    ]

    resources = [
      aws_sns_topic.image_notification.arn
    ]

    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"

      values = [
        aws_s3_bucket.image_bucket.arn
      ]
    }
  }
}


data "aws_iam_policy_document" "sqs_queue_policy" {
  statement {
    sid    = "AllowSNSMessages"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["sns.amazonaws.com"]
    }

    actions = [
      "sqs:SendMessage"
    ]

    resources = [
      aws_sqs_queue.image_queue.arn
    ]

    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"

      values = [
        aws_sns_topic.image_notification.arn
      ]
    }
  }
}

data "aws_region" "current" {}