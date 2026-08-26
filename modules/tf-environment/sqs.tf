resource "aws_sqs_queue" "image_queue" {
  name = var.sqs_name

  fifo_queue                 = false
  visibility_timeout_seconds = 180
  sqs_managed_sse_enabled    = true
}

resource "aws_sqs_queue_policy" "image_queue_policy" {
  queue_url = aws_sqs_queue.image_queue.id
  policy    = data.aws_iam_policy_document.sqs_queue_policy.json
}

resource "aws_sns_topic_subscription" "image_queue_subscription" {
  topic_arn = aws_sns_topic.image_notification.arn
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.image_queue.arn
}