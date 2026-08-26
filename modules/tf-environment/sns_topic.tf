resource "aws_sns_topic" "image_notification" {
  name = var.sns_name
}

resource "aws_sns_topic_policy" "image_notification_policy" {
  arn    = aws_sns_topic.image_notification.arn
  policy = data.aws_iam_policy_document.sns_topic_policy.json
}