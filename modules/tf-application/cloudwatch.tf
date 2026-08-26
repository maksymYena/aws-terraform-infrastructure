# Customer-managed KMS encryption is outside the scope of this training environment.
#tfsec:ignore:aws-cloudwatch-log-group-customer-key
resource "aws_cloudwatch_log_group" "ecs_logs" {
  #checkov:skip=CKV_AWS_158:Customer-managed KMS is outside the scope of this training environment.
  name              = "/ecs/image-recognition"
  retention_in_days = 365
}