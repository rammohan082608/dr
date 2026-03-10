output "api_gateway_invoke_url2" {
  description = "The invoke URL for the API Gateway stage."
  value       = module.api_gateway.apigateway_invoke_url2
}

output "cognito_user_pool_id" {
  description = "The ID of the Cognito User Pool."
  value       = module.cognito.cognito_user_pool_id
}

output "cognito_user_pool_client_id" {
  description = "The ID of the Cognito User Pool Client."
  value       = module.cognito.cognito_app_client_id
}

output "apprunner_service_url" {
  description = "Mock Quest quanhub url"
  value       = module.mock_quanum_hub.service_url
}

output "nlb_dns_name" {
  description = "DNS name of nlb"
  value       = module.ecs_processor.nlb_dns_name
}

output "dynamodb_table_name" {
  description = "Name of the dynamodb table"
  value       = module.dynamodb.dynamodb_id
}

output "dr_api_gateway_invoke_url2" {
  description = "The invoke URL for the API Gateway stage in DR region."
  value       = module.api_gateway_dr.apigateway_invoke_url2
}

output "dr_cognito_user_pool_id" {
  description = "The ID of the Cognito User Pool in DR region."
  value       = module.cognito_dr.cognito_user_pool_id
}

output "dr_cognito_user_pool_client_id" {
  description = "The ID of the Cognito User Pool Client in DR region."
  value       = module.cognito_dr.cognito_app_client_id
}

output "dr_apprunner_service_url" {
  description = "Mock Quest quanhub url in DR region"
  value       = module.mock_quanum_hub_dr.service_url
}

output "dr_nlb_dns_name" {
  description = "DNS name of nlb in DR region"
  value       = module.ecs_processor_dr.nlb_dns_name
}
