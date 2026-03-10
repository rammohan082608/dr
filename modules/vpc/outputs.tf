output "vpc_id" {
  description = "The ID of the new VPC."
  value       = aws_vpc.main.id
}

output "private_subnet_ids" {
  description = "A list of subnet IDs in the default VPC."
  value       = aws_subnet.private[*].id
}
