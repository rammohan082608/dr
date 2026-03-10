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

variable "api_gateway_arn" {
  description = "ARN of the HTTP API Gateway stage"
  type        = string
}

variable "cognito_user_pool_arn" {
  description = "ARN of the Cognito User Pool"
  type        = string
}

variable "kms_key_arn" {
  description = "The ARN of the KMS key for CloudWatch Log encryption."
  type        = string
}