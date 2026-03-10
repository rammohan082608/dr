resource "aws_cognito_user_pool" "user_pool" {
  name = "${var.name_prefix}-user-pool"

  # Requires an email for sign-up
  username_attributes = ["email"]

  user_pool_add_ons {
    advanced_security_mode = "AUDIT"

    advanced_security_additional_flows {
      custom_auth_mode = "AUDIT"
    }
  }

  dynamic "lambda_config" {
    for_each = var.sync_lambda_arn != "" ? [1] : []
    content {
      post_authentication = var.sync_lambda_arn
      post_confirmation   = var.sync_lambda_arn
    }
  }
}

resource "aws_cognito_user_pool_client" "app_client" {
  name         = "${var.name_prefix}-default-client"
  user_pool_id = aws_cognito_user_pool.user_pool.id

  read_attributes                      = ["email", "email_verified"]
  write_attributes                     = ["name"]
  explicit_auth_flows                  = ["ALLOW_USER_PASSWORD_AUTH", "ALLOW_REFRESH_TOKEN_AUTH"]
  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_flows                  = ["code", "implicit"]
  allowed_oauth_scopes                 = ["email", "openid"]

  token_validity_units {
    access_token  = "minutes"
    id_token      = "minutes"
    refresh_token = "days"
  }
  access_token_validity  = 60
  id_token_validity      = 60
  refresh_token_validity = 30
  callback_urls          = ["https://localhost:3000/callback"]
}

resource "aws_cloudwatch_log_group" "cognito_user_activity" {
  name              = "/aws/cognito/${var.name_prefix}/user-activity-logs"
  kms_key_id        = var.kms_key_arn
  retention_in_days = 7
}

# IAM Role Trust Policy (Allows Cognito to assume the role)
resource "aws_iam_role" "cognito_logs_role" {
  name = "${var.name_prefix}-CognitoLogDeliveryRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          # This service principal is required for log delivery
          Service = "cognito-idp.amazonaws.com"
        }
        Condition = {
          # Add a condition to limit the role to the specific User Pool
          "StringEquals" : {
            "sts:ExternalId" : aws_cognito_user_pool.user_pool.arn
          }
        }
      },
    ]
  })
}

# IAM Policy (Grants permission to write logs)
resource "aws_iam_policy" "cognito_logs_policy" {
  name = "${var.name_prefix}-CognitoLogDeliveryPolicy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Effect   = "Allow"
        Resource = "${aws_cloudwatch_log_group.cognito_user_activity.arn}:*"
      },
    ]
  })
}

# Attach the policy to the role
resource "aws_iam_role_policy_attachment" "cognito_logs_attach" {
  role       = aws_iam_role.cognito_logs_role.name
  policy_arn = aws_iam_policy.cognito_logs_policy.arn
}

# Log configuration to log all auth events
resource "aws_cognito_log_delivery_configuration" "main_logs" {
  user_pool_id = aws_cognito_user_pool.user_pool.id

  log_configurations {
    event_source = "userAuthEvents"
    log_level    = "INFO"

    cloud_watch_logs_configuration {
      log_group_arn = aws_cloudwatch_log_group.cognito_user_activity.arn
    }
  }
}


resource "aws_cognito_risk_configuration" "main" {
  user_pool_id = aws_cognito_user_pool.user_pool.id # Reference your existing User Pool

  # --- Adaptive Authentication Configuration ---
  # risk_exception_configuration {
  #   # Optional: List of IP addresses to exclude from risk detection
  #   # blocked_ip_range_list = []
  #   skipped_ip_range_list = []
  # }

  account_takeover_risk_configuration {

    # Define actions based on risk score (Adaptive Authentication)
    actions {
      high_action {
        event_action = "NO_ACTION" #"BLOCK" 
        # Notify user (optional)
        notify = false
      }
      medium_action {
        event_action = "NO_ACTION"
        notify       = false #true
      }
      low_action {
        event_action = "NO_ACTION"
        notify       = false
      }
    }
  }

  # Enable Compromised Credentials Detection
  compromised_credentials_risk_configuration {
    actions {
      # Action when compromised credentials are detected
      event_action = "BLOCK"
    }
  }

  risk_exception_configuration {
    #  blocked_ip_range_list = []
    skipped_ip_range_list = [
      "122.172.82.89/32",
    ]
  }
}

resource "aws_lambda_permission" "allow_cognito" {
  count         = var.enable_sync_lambda ? 1 : 0
  statement_id  = "AllowExecutionFromCognito"
  action        = "lambda:InvokeFunction"
  function_name = var.sync_lambda_arn
  principal     = "cognito-idp.amazonaws.com"
  source_arn    = aws_cognito_user_pool.user_pool.arn
}
