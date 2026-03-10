# IAM Role for API Gateway Logging
resource "aws_iam_role" "apigw_logs" {
  name = "${var.name_prefix}-apigw-logs-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "apigateway.amazonaws.com"
      }
    }]
  })
}

# Policy to allow writing to CloudWatch Logs
resource "aws_iam_policy" "apigw_logs_policy" {
  name = "${var.name_prefix}-apigw-logs-policy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ]
      Effect   = "Allow"
      Resource = "*" # Resource must be '*' for log policies
    }]
  })
}

# Attach Policy to Role
resource "aws_iam_role_policy_attachment" "apigw_logs_attach" {
  role       = aws_iam_role.apigw_logs.name
  policy_arn = aws_iam_policy.apigw_logs_policy.arn
}

# Dedicated Log Group for Access Logs
resource "aws_cloudwatch_log_group" "apigw_access_logs" {
  name              = "/aws/apigw/${var.name_prefix}/access"
  kms_key_id        = var.kms_key_arn
  retention_in_days = 7
}

resource "aws_api_gateway_rest_api" "alb_proxy_api" {
  name = "${var.name_prefix}-rest-api"

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "aws_api_gateway_authorizer" "cognito" {
  name            = "CognitoJWTAuthorizer"
  rest_api_id     = aws_api_gateway_rest_api.alb_proxy_api.id
  type            = "COGNITO_USER_POOLS"
  identity_source = "method.request.header.Authorization"
  provider_arns   = [var.cognito_user_pool_arn]
}

# Root resource ("/")
data "aws_api_gateway_resource" "root" {
  rest_api_id = aws_api_gateway_rest_api.alb_proxy_api.id
  path        = "/"
}

# /{proxy+}
resource "aws_api_gateway_resource" "proxy" {
  rest_api_id = aws_api_gateway_rest_api.alb_proxy_api.id
  parent_id   = data.aws_api_gateway_resource.root.id
  path_part   = "{proxy+}"
}

resource "aws_api_gateway_vpc_link" "nlb_link" {
  name        = "${var.name_prefix}-vpc-link"
  target_arns = [var.nlb_arn]
}

resource "aws_api_gateway_method" "proxy_any" {
  rest_api_id   = aws_api_gateway_rest_api.alb_proxy_api.id
  resource_id   = aws_api_gateway_resource.proxy.id
  http_method   = "ANY"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.cognito.id
  request_parameters = {
    "method.request.path.proxy" = true
  }
}

resource "aws_api_gateway_integration" "alb_integration" {
  rest_api_id             = aws_api_gateway_rest_api.alb_proxy_api.id
  resource_id             = aws_api_gateway_resource.proxy.id
  http_method             = aws_api_gateway_method.proxy_any.http_method
  integration_http_method = "ANY"
  type                    = "HTTP_PROXY"
  # API Gateway will forward the path and querystring; use the NLB DNS
  uri             = "http://${var.nlb_dns_name}:8000/{proxy}"
  connection_type = "VPC_LINK"
  connection_id   = aws_api_gateway_vpc_link.nlb_link.id

  passthrough_behavior = "WHEN_NO_MATCH"

  request_parameters = {
    # forward all headers and path
    "integration.request.path.proxy" = "method.request.path.proxy"
  }
}

resource "aws_api_gateway_deployment" "deploy" {
  depends_on = [
    aws_api_gateway_integration.alb_integration,
    # aws_api_gateway_integration_response.mock_integration_200
  ]

  rest_api_id = aws_api_gateway_rest_api.alb_proxy_api.id
}

resource "aws_api_gateway_stage" "prod" {
  stage_name           = "api"
  rest_api_id          = aws_api_gateway_rest_api.alb_proxy_api.id
  deployment_id        = aws_api_gateway_deployment.deploy.id
  xray_tracing_enabled = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.apigw_access_logs.arn
    format = jsonencode({
      requestId   = "$context.requestId"
      httpMethod  = "$context.httpMethod"
      path        = "$context.resourcePath"
      sourceIp    = "$context.identity.sourceIp"
      status      = "$context.status"
      error       = "$context.error.message"
      authorizer  = "$context.authorizer.error"
      path        = "$context.path" # Use this for REST
      claimsEmail = "$context.authorizer.claims.email"
      claimsSub   = "$context.authorizer.claims.sub"
    })
  }

  variables = {
    env = "prod"
  }
}
