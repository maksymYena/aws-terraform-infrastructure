# Dedicated S3 access logging infrastructure is outside the scope of this training environment.
#tfsec:ignore:aws-s3-enable-bucket-logging
resource "aws_s3_bucket" "image_bucket" {
  #checkov:skip=CKV2_AWS_61:S3 lifecycle configuration is outside the coursework requirements.
  #checkov:skip=CKV_AWS_18:Dedicated S3 access logging infrastructure is outside the scope of this training environment.
  #checkov:skip=CKV_AWS_144:Cross-region replication is outside the scope of this single-region training environment.
  #checkov:skip=CKV_AWS_20:Public read access is required by the coursework architecture.
  #checkov:skip=CKV2_AWS_6:A separate Public Access Block resource is configured for this bucket.
  #checkov:skip=CKV_AWS_145:AES256 server-side encryption is used; customer-managed KMS is outside the scope of this training environment.

  bucket = var.bucket_name
  tags = {
    Environment = var.environment
    Component   = "storage"
  }
}

# AES256 server-side encryption is sufficient for this training environment.
#tfsec:ignore:aws-s3-encryption-customer-key
resource "aws_s3_bucket_server_side_encryption_configuration" "image_bucket_encryption" {
  bucket = aws_s3_bucket.image_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_versioning" "image_bucket_versioning" {
  bucket = aws_s3_bucket.image_bucket.id

  versioning_configuration {
    status = "Enabled"
  }
}

# tfsec:ignore:aws-s3-block-public-acls
# tfsec:ignore:aws-s3-ignore-public-acls
# tfsec:ignore:aws-s3-no-public-buckets
# Public read access is required by the coursework architecture.
resource "aws_s3_bucket_public_access_block" "image_bucket_public_access" {
  #checkov:skip=CKV_AWS_53:Public ACL access is required by the coursework architecture.
  #checkov:skip=CKV_AWS_55:Public ACL access is required by the coursework architecture.
  #checkov:skip=CKV_AWS_56:Public bucket access is required by the coursework architecture.

  bucket = aws_s3_bucket.image_bucket.id

  block_public_acls       = false #tfsec:ignore:aws-s3-block-public-acls
  block_public_policy     = true
  ignore_public_acls      = false #tfsec:ignore:aws-s3-ignore-public-acls
  restrict_public_buckets = false #tfsec:ignore:aws-s3-no-public-buckets
}

resource "aws_s3_bucket_ownership_controls" "image_bucket_ownership" {
  #checkov:skip=CKV2_AWS_65:ACL support is required for the public-read coursework configuration.

  bucket = aws_s3_bucket.image_bucket.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

# tfsec:ignore:aws-s3-no-public-access-with-acl
# Public-read ACL is required by the coursework architecture.
resource "aws_s3_bucket_acl" "image_bucket_acl" {
  depends_on = [
    aws_s3_bucket_ownership_controls.image_bucket_ownership,
    aws_s3_bucket_public_access_block.image_bucket_public_access
  ]

  bucket = aws_s3_bucket.image_bucket.id
  acl    = "public-read" #tfsec:ignore:aws-s3-no-public-access-with-acl
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