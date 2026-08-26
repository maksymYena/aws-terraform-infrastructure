resource "aws_dynamodb_table" "recognition_results" {
  name           = "recognition-results"
  billing_mode   = "PROVISIONED"
  read_capacity  = 5
  write_capacity = 5

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

  global_secondary_index {
    name            = "LabelValue-index"
    hash_key        = "LabelValue"
    projection_type = "ALL"

    read_capacity  = 5
    write_capacity = 5
  }
}