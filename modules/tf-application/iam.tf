resource "aws_iam_role" "lambda_role" {
  name = "image-recognition-lambda-role-${var.environment}"

  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

resource "aws_iam_policy" "lambda_policy" {
   name = "image-recognition-lambda-policy-${var.environment}"
  policy = data.aws_iam_policy_document.lambda_permissions.json
}

resource "aws_iam_policy_attachment" "lambda_policy_attachment" {
  name       = "lambda-policy-attachment-${var.environment}"
  roles      = [aws_iam_role.lambda_role.name]
  policy_arn = aws_iam_policy.lambda_policy.arn
}


resource "aws_iam_role" "ecs_execution_role" {
  name = "image-recognition-ecs-execution-role-${var.environment}"

  assume_role_policy = data.aws_iam_policy_document.ecs_execution_assume_role.json
}

resource "aws_iam_policy_attachment" "ecs_execution_policy" {
  name       = "ecs-execution-policy-${var.environment}"
  roles      = [aws_iam_role.ecs_execution_role.name]
  policy_arn = data.aws_iam_policy.ecs_execution_policy.arn
}


resource "aws_iam_role" "ecs_task_role" {
  name = "image-recognition-ecs-task-role-${var.environment}"

  assume_role_policy = data.aws_iam_policy_document.ecs_execution_assume_role.json
}

resource "aws_iam_policy_attachment" "ecs_s3_access" {
  name       = "ecs-s3-access-${var.environment}"
  roles      = [aws_iam_role.ecs_task_role.name]
  policy_arn = data.aws_iam_policy.ecs_s3_access.arn
}

resource "aws_iam_policy_attachment" "ecs_dynamodb_access" {
  name       = "ecs-dynamodb-access-${var.environment}"
  roles      = [aws_iam_role.ecs_task_role.name]
  policy_arn = data.aws_iam_policy.ecs_dynamodb_access.arn
}