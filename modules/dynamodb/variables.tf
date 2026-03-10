terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      
    }
  }
}

variable "name_prefix" {
  description = "Standardized prefix for naming resources"
  type        = string
}

variable "kms_key_arn" {
  description = "The ARN of the KMS key for CloudWatch Log encryption."
  type        = string
}

variable "replica_region" {
  description = "Region for DynamoDB global table replica"
  type        = string
}