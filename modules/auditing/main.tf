data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

resource "aws_s3_bucket_policy" "cloudtrail_policy" {
  bucket = split(":", var.s3_bucket_arn)[5]
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid       = "AWSCloudTrailAclCheck",
        Effect    = "Allow",
        Principal = { Service = "cloudtrail.amazonaws.com" },
        Action    = "s3:GetBucketAcl",
        Resource  = var.s3_bucket_arn,
        Condition = {
          StringEquals = {
            "aws:SourceArn" = "arn:aws:cloudtrail:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:trail/${var.name_prefix}-trail"
          }
        }
      },
      {
        Sid       = "AWSCloudTrailWrite",
        Effect    = "Allow",
        Principal = { Service = "cloudtrail.amazonaws.com" },
        Action    = "s3:PutObject",
        Resource  = "${var.s3_bucket_arn}/cloudtrail-logs/AWSLogs/${data.aws_caller_identity.current.account_id}/*",
        Condition = {
          StringEquals = {
            "aws:SourceArn" = "arn:aws:cloudtrail:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:trail/${var.name_prefix}-trail",
            "s3:x-amz-acl"  = "bucket-owner-full-control"
          }
        }
      }
    ]
  })
}

# --- CloudWatch Log Group for CloudTrail ---
resource "aws_cloudwatch_log_group" "cloudtrail_logs" {
  name              = "/aws/${var.name_prefix}/cloudtrail"
  retention_in_days = 7
  kms_key_id        = var.kms_key_arn
}

# --- IAM Role for CloudTrail to write to CloudWatch ---
resource "aws_iam_role" "cloudtrail_cw_role" {
  name = "${var.name_prefix}-cloudtrail-cloudwatch-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "cloudtrail.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "cloudtrail_cw_policy" {
  name = "${var.name_prefix}-cloudtrail-cloudwatch-policy"
  role = aws_iam_role.cloudtrail_cw_role.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Action = [
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      Resource = "${aws_cloudwatch_log_group.cloudtrail_logs.arn}:*"
    }]
  })
}

# --- CloudTrail Trail ---
resource "aws_cloudtrail" "main_trail" {
  name                          = "${var.name_prefix}-trail"
  s3_bucket_name                = split(":", var.s3_bucket_arn)[5]
  s3_key_prefix                 = "cloudtrail-logs"
  include_global_service_events = true
  is_multi_region_trail         = true
  enable_logging                = true
  # kms_key_id                    = var.kms_key_arn

  cloud_watch_logs_group_arn = "${aws_cloudwatch_log_group.cloudtrail_logs.arn}:*"
  cloud_watch_logs_role_arn  = aws_iam_role.cloudtrail_cw_role.arn

  depends_on = [
    aws_s3_bucket_policy.cloudtrail_policy,
    aws_iam_role_policy.cloudtrail_cw_policy
  ]
}

# # --- Best Practice: CloudWatch Alarm for Auth Failures ---
# resource "aws_cloudwatch_log_metric_filter" "auth_failures_filter" {
#   name           = "ConsoleSignInFailures"
#   pattern        = "{ ($.eventName = \"ConsoleLogin\") && ($.errorMessage = \"Failed authentication\") }"
#   log_group_name = aws_cloudwatch_log_group.cloudtrail_logs.name

#   metric_transformation {
#     name      = "ConsoleSignInFailures"
#     namespace = "CloudTrailMetrics"
#     value     = "1"
#   }
# }

# resource "aws_cloudwatch_metric_alarm" "auth_failures_alarm" {
#   alarm_name          = "console-signin-failures-alarm"
#   comparison_operator = "GreaterThanOrEqualToThreshold"
#   evaluation_periods  = "1"
#   metric_name         = aws_cloudwatch_log_metric_filter.auth_failures_filter.metric_transformation[0].name
#   namespace           = aws_cloudwatch_log_metric_filter.auth_failures_filter.metric_transformation[0].namespace
#   period              = "300" # 5 minutes
#   statistic           = "Sum"
#   threshold           = "3" # 3 failures in 5 minutes
#   alarm_description   = "Alarm for 3 or more console sign-in failures in 5 minutes."
#   # In production, you would add an SNS topic ARN to 'alarm_actions'
# }
