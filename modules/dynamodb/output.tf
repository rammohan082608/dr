output "dynamodb_id" {
  description = "Name of the dynamodb table"
  value       = aws_dynamodb_table.reconciliation_db.id
}

output "dynamodb_arn" {
  description = "ARN of the dynamodb table"
  value       = aws_dynamodb_table.reconciliation_db.arn
}
