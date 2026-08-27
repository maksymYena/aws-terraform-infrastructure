# tfsec:ignore:aws-sns-topic-encryption-use-cmk
# AWS-managed SNS KMS key is sufficient for this training environment.
resource "aws_sns_topic" "image_notification" {
  name = var.sns_name
  tags = {
    Environment = var.environment
    Component   = "messaging-topic"
  }
}

resource "aws_sns_topic_policy" "image_notification_policy" {
  arn    = aws_sns_topic.image_notification.arn
  policy = data.aws_iam_policy_document.sns_topic_policy.json
}