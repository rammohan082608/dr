output "mock_client_apprunner_url" {
  description = "The public URL for the App Runner service (Can be called by ECS)."
  value       = aws_apprunner_service.mock_client_service.service_url
}

output "service_url" {
  description = "Full URL"
  value       = "https://${aws_apprunner_service.mock_client_service.service_url}"
}