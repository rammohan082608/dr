data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/lambda/sync.py"
  output_path = "${path.module}/lambda/sync.zip"
}

resource "aws_iam_role" "lambda_exec" {
  name = "${var.name_prefix}-cognito-sync-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_policy" "cognito_dr_access" {
  name = "${var.name_prefix}-cognito-dr-sync-access"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = [
        "cognito-idp:AdminCreateUser",
        "cognito-idp:AdminUpdateUserAttributes",
        "cognito-idp:AdminGetUser"
      ]
      Effect   = "Allow"
      Resource = "arn:aws:cognito-idp:${var.dr_region}:*:userpool/${var.dr_user_pool_id}"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_cognito" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = aws_iam_policy.cognito_dr_access.arn
}

resource "aws_lambda_function" "sync_lambda" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = "${var.name_prefix}-cognito-sync"
  role             = aws_iam_role.lambda_exec.arn
  handler          = "sync.lambda_handler"
  runtime          = "python3.12"
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  environment {
    variables = {
      DR_REGION       = var.dr_region
      DR_USER_POOL_ID = var.dr_user_pool_id
    }
  }
}
