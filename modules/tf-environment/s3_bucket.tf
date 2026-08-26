resource "aws_s3_bucket" "image_bucket" {
  bucket = var.bucket_name
}

resource "aws_s3_bucket_public_access_block" "image_bucket_public_access" {
  bucket = aws_s3_bucket.image_bucket.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_ownership_controls" "image_bucket_ownership" {
  bucket = aws_s3_bucket.image_bucket.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "image_bucket_acl" {
  depends_on = [
    aws_s3_bucket_ownership_controls.image_bucket_ownership,
    aws_s3_bucket_public_access_block.image_bucket_public_access
  ]

  bucket = aws_s3_bucket.image_bucket.id
  acl    = "public-read"
}

resource "aws_s3_bucket_policy" "image_bucket_policy" {
  bucket = aws_s3_bucket.image_bucket.id
  policy = data.aws_iam_policy_document.image_bucket_policy.json
}

resource "aws_s3_bucket_notification" "image_notification" {
  bucket = aws_s3_bucket.image_bucket.id

  topic {
    topic_arn = aws_sns_topic.image_notification.arn
    events    = ["s3:ObjectCreated:*"]
  }

  depends_on = [
    aws_sns_topic_policy.image_notification_policy
  ]
}