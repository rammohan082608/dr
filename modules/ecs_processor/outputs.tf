output "nlb_arn" {
  description = "ARN of network load balancer"
  value       = aws_lb.nlb.arn
}

output "nlb_dns_name" {
  description = "The internal DNS name of the NLB."
  value       = aws_lb.nlb.dns_name
}