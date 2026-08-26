resource "aws_cloudwatch_log_group" "ecs_logs" {
  name              = "/ecs/image-recognition"
  retention_in_days = 365
}