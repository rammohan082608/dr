resource "aws_dynamodb_table" "reconciliation_db" {
  name             = "${var.name_prefix}-reconciliation"
  billing_mode     = "PAY_PER_REQUEST"
  hash_key         = "item_id"
  stream_enabled   = true
  stream_view_type = "NEW_AND_OLD_IMAGES"

  replica {
    region_name = var.replica_region
  }

  # Attributes must be defined for any field used as a Key or Index
  attribute {
    name = "item_id"
    type = "S"
  }
  attribute {
    name = "lab_id"
    type = "S"
  }
  attribute {
    name = "order_id"
    type = "S"
  }
  attribute {
    name = "accession_id"
    type = "S"
  }
  attribute {
    name = "created_at"
    type = "N" # 'N' for Number (Unix Timestamp)
  }
  attribute {
    name = "message_control_id"
    type = "S"
  }

  # GSI for lab_id
  global_secondary_index {
    name            = "LabOrderIndex"
    hash_key        = "lab_id"
    range_key       = "order_id"
    projection_type = "ALL"
  }

  # GSI for accession_id
  global_secondary_index {
    name            = "AccessionIdIndex"
    hash_key        = "lab_id"
    range_key       = "accession_id"
    projection_type = "ALL"
  }

  global_secondary_index {
    name            = "ControlIdIndex"
    hash_key        = "lab_id"
    range_key       = "message_control_id"
    projection_type = "ALL"
  }

  global_secondary_index {
    name            = "CreatedIndex"
    hash_key        = "lab_id"     # Partition by Lab
    range_key       = "created_at" # Sort by Time
    projection_type = "ALL"
  }
}

/*
resource "aws_iam_policy" "dynamo_access" {
  name        = "ECS-DynamoDB-Access-Policy"
  description = "Allows ECS tasks to Read/Write to the LabOrders table"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "dynamodb:PutItem",
          "dynamodb:GetItem",
          "dynamodb:UpdateItem",
          "dynamodb:Query",
          "dynamodb:BatchWriteItem"
        ]
        Effect   = "Allow"
        # Grant access to the table AND its indexes (GSIs)
        Resource = [
          aws_dynamodb_table.lab_results.arn,
          "${aws_dynamodb_table.lab_results.arn}/index/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_dynamo_attach" {
  role       = aws_iam_role.ecs_task_role.name # The role used in your task_definition
  policy_arn = aws_iam_policy.dynamo_access.arn
}

resource "aws_dynamodb_table" "lab_results" {
  name           = "LabOrders"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "item_id"

  # --- AUDIT SETTINGS ---
  # Allows restoring to any point in the last 35 days
  point_in_time_recovery {
    enabled = true
  }

  # Captures "Before" and "After" images of every change
  stream_enabled   = true
  stream_view_type = "NEW_AND_OLD_IMAGES" 

  # (Previous attribute and GSI blocks from the first response go here)
  attribute { name = "item_id" type = "S" }
}

resource "aws_cloudtrail" "dynamo_data_audit" {
  name                          = "dynamodb-data-events-trail"
  s3_bucket_name                = aws_s3_bucket.audit_logs.id
  include_global_service_events = false

  # This block specifically targets your LabOrders table for data-level auditing
  event_selector {
    read_write_type           = "All" # Logs both Reads (Queries) and Writes
    include_management_events = true

    data_resource {
      type   = "AWS::DynamoDB::Table"
      values = ["${aws_dynamodb_table.lab_results.arn}"]
    }
  }
}

resource "aws_s3_bucket" "audit_logs" {
  bucket = "my-lab-audit-logs-storage"
}

# 1. IAM Role for the Audit Lambda
resource "aws_iam_role" "audit_lambda_role" {
  name = "LabAuditLambdaRole"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

# 2. Permissions to read the stream
resource "aws_iam_role_policy" "stream_read_policy" {
  role = aws_iam_role.audit_lambda_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = [
        "dynamodb:DescribeStream",
        "dynamodb:GetRecords",
        "dynamodb:GetShardIterator",
        "dynamodb:ListStreams"
      ]
      Effect   = "Allow"
      Resource = "${aws_dynamodb_table.lab_results.stream_arn}"
    }]
  })
}

# 3. The Trigger (Link Stream to Lambda)
resource "aws_lambda_event_source_mapping" "audit_trigger" {
  event_source_arn  = aws_dynamodb_table.lab_results.stream_arn
  function_name     = aws_lambda_function.audit_processor.arn
  starting_position = "LATEST"
}
*/