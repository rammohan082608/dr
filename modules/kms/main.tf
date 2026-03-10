terraform {
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      configuration_aliases = [aws, aws.dr]
    }
  }
}

variable "name_prefix" {
  description = "Standardized prefix for naming resources"
  type        = string
}

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

data "aws_region" "dr" {
  provider = aws.dr
}

data "aws_iam_policy_document" "kms_logs_policy" {
  # 1. Standard: Enable IAM User Permissions (Allows you to manage the key)
  statement {
    sid    = "Enable IAM User Permissions"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
    actions   = ["kms:*"]
    resources = ["*"]
  }

    # 2. Critical: Allow CloudWatch Logs to use the key
    statement {
      sid    = "Allow CloudWatch Logs"
      effect = "Allow"
      principals {
        type = "Service"
        # Format: logs.<region>.amazonaws.com
        identifiers = [
          "logs.${data.aws_region.current.id}.amazonaws.com",
          "logs.${data.aws_region.dr.id}.amazonaws.com"
        ]
      }
    actions = [
      "kms:Encrypt*",
      "kms:Decrypt*",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:Describe*"
    ]
    resources = ["*"]

    # Best Practice: Restrict this to logs within your own account
    # condition {
    #   test     = "ArnLike"
    #   variable = "kms:EncryptionContext:aws:logs:arn"
    #   values   = ["arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:*"]
    # }
  }
}

resource "aws_kms_key" "middleware_key" {
  description             = "KMS key for encrypting middleware logs"
  enable_key_rotation     = true
  deletion_window_in_days = 10
  multi_region            = true
  policy                  = data.aws_iam_policy_document.kms_logs_policy.json
  tags = {
    Name = "middleware-key"
  }
}

resource "aws_kms_alias" "middleware_key_alias" {
  name          = "alias/${var.name_prefix}"
  target_key_id = aws_kms_key.middleware_key.key_id
}

resource "aws_kms_replica_key" "middleware_key_replica" {
  provider                = aws.dr
  description             = "KMS replica key for encrypting middleware logs in DR region"
  deletion_window_in_days = 10
  primary_key_arn         = aws_kms_key.middleware_key.arn
  policy                  = data.aws_iam_policy_document.kms_logs_policy.json
}

resource "aws_kms_alias" "middleware_key_replica_alias" {
  provider      = aws.dr
  name          = "alias/${var.name_prefix}"
  target_key_id = aws_kms_replica_key.middleware_key_replica.key_id
}