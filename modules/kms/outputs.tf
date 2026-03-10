output "kms_key_id" {
  description = "The ID of the KMS key."
  value       = aws_kms_key.middleware_key.id
}

output "kms_key_arn" {
  description = "The ARN of the KMS key."
  value       = aws_kms_key.middleware_key.arn
}

output "kms_key_dr_arn" {
  description = "The ARN of the KMS Replica key in DR region."
  value       = aws_kms_replica_key.middleware_key_replica.arn
}
