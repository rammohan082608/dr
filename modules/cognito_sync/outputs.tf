output "lambda_arn" {
  description = "The ARN of the Cognito Sync Lambda function"
  value       = aws_lambda_function.sync_lambda.arn
}
