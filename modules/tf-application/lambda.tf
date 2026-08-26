resource "aws_lambda_function" "image_recognition" {
  #checkov:skip=CKV_AWS_272:Code signing is outside the scope of this training environment.
  #checkov:skip=CKV_AWS_116:SQS provides retry semantics for this training workflow.
  #checkov:skip=CKV_AWS_173:Customer-managed KMS is outside the scope of this training environment.
  #checkov:skip=CKV_AWS_115:Reserved concurrency is not required for this training workload.
  #checkov:skip=CKV_AWS_117:Lambda VPC placement is outside the scope of this training architecture.

  function_name = "image-recognition-lambda"

  role     = aws_iam_role.lambda_role.arn
  filename = data.archive_file.lambda_zip.output_path

  runtime = "python3.10"
  handler = "index.lambda_handler"

  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  timeout = 30

  tracing_config {
    mode = "Active"
  }

  environment {
    variables = {
      DYNAMODB_TABLE_NAME = var.dynamodb_name
    }
  }
}

resource "aws_lambda_event_source_mapping" "sqs_to_lambda" {
  event_source_arn = var.sqs_queue_arn
  function_name    = aws_lambda_function.image_recognition.arn
  batch_size       = 1

  depends_on = [
    aws_iam_policy_attachment.lambda_policy_attachment
  ]
}