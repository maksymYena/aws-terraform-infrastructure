# tfsec:ignore:aws-dynamodb-table-customer-key
# AWS-managed encryption is sufficient for this training environment.
resource "aws_dynamodb_table" "recognition_results" {
  name           = "recognition-results-${var.environment}"
  billing_mode   = "PROVISIONED"
  read_capacity  = 5
  write_capacity = 5

  point_in_time_recovery {
    enabled = true
  }
  #tfsec:ignore:aws-dynamodb-table-customer-key
  server_side_encryption {
    enabled = true
  }

  hash_key  = "ImageName"
  range_key = "LabelValue"

  attribute {
    name = "ImageName"
    type = "S"
  }

  attribute {
    name = "LabelValue"
    type = "S"
  }

  tags = {
    Environment = var.environment
    Component   = "database"
  }

  global_secondary_index {
    name            = "LabelValue-index"
    hash_key        = "LabelValue"
    projection_type = "ALL"

    read_capacity  = 5
    write_capacity = 5
  }
}