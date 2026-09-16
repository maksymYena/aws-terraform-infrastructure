resource "aws_iam_role" "lambda_role" {
  name = "image-recognition-lambda-role-${var.environment}"

  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

resource "aws_iam_policy" "lambda_policy" {
  name   = "image-recognition-lambda-policy-${var.environment}"
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

resource "aws_iam_role_policy" "ecs_s3_write_access" {
  name = "ecs-s3-write-access-${var.environment}"
  role = aws_iam_role.ecs_task_role.id

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Action = [
          "s3:GetObject",
          "s3:PutObject"
        ]

        Resource = "arn:aws:s3:::${var.bucket_name}/*"
      }
    ]
  })
}

resource "aws_iam_role_policy" "ecs_dynamodb_read_access" {
  name = "ecs-dynamodb-read-access-${var.environment}"
  role = aws_iam_role.ecs_task_role.id

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Action = [
          "dynamodb:GetItem",
          "dynamodb:Query",
          "dynamodb:Scan"
        ]

        Resource = [
          "arn:aws:dynamodb:${var.region_name}:888840134536:table/${var.dynamodb_name}",
          "arn:aws:dynamodb:${var.region_name}:888840134536:table/${var.dynamodb_name}/index/*"
        ]
      }
    ]
  })
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