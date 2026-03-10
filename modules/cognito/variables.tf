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

variable "sync_lambda_arn" {
  description = "Optional ARN for Cognito Sync Lambda trigger"
  type        = string
  default     = ""
}

variable "enable_sync_lambda" {
  description = "Whether to attach a sync lambda to the Cognito User Pool"
  type        = bool
  default     = false
}