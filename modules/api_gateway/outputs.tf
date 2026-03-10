output "apigateway_invoke_url2" {
  description = "The Secure API Gateway Invoke URL."
  value       = aws_api_gateway_stage.prod.invoke_url
}

output "rest_api_arn" {
  description = "ARN of the REST API Gateway stage"
  value       = aws_api_gateway_stage.prod.arn
}

output "rest_api_id" {
  description = "ID of the REST API Gateway stage"
  value       = aws_api_gateway_rest_api.alb_proxy_api.id
}