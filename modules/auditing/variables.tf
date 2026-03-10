terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      
    }
  }
}

variable "kms_key_arn" {
  description = "The ARN of the KMS key for CloudWatch Log encryption."
  type        = string
}

variable "s3_bucket_arn" {
  description = "The S3 bucket run for logs and cloudtrail"
  type        = string
}

variable "name_prefix" {
  description = "Standardized prefix for naming resources"
  type        = string
}