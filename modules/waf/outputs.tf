output "web_acl_arn" {
  value       = aws_wafv2_web_acl.hl7_security.arn
  description = "ARN of the WAF Web ACL for API Gateway and Cognito"
}

output "web_acl_id" {
  value       = aws_wafv2_web_acl.hl7_security.id
  description = "ID of the WAF Web ACL"
}

output "waf_log_group_name" {
  value       = aws_cloudwatch_log_group.waf_logs.name
  description = "CloudWatch log group for WAF logging"
}