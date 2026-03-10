output "cognito_user_pool_id" {
  description = "The ID of the Cognito User Pool"
  value       = aws_cognito_user_pool.user_pool.id
}

output "cognito_pool_arn" {
  description = "The ARN of the Cognito User Pool."
  value       = aws_cognito_user_pool.user_pool.arn
}

output "cognito_app_client_id" {
  description = "The ID of the App Client (for sign-in)"
  value       = aws_cognito_user_pool_client.app_client.id
}

output "cognito_user_pool_endpoint" {
  description = "URL of cognito user pool"
  value       = aws_cognito_user_pool.user_pool.endpoint
}