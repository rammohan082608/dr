terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      
    }
  }
}

variable "aws_region" {
  description = "The AWS region."
  type        = string
}

# variable "cognito_user_pool_endpoint" {
#   description = "The URL of the Cognito User Pool for the authorizer."
#   type        = string
# }

variable "cognito_user_pool_arn" {
  description = "The ARN of the Cognito User Pool for the authorizer."
  type        = string
}

# variable "cognito_app_client_id" {
#   description = "Cognito user pool app client id"
#   type        = string
# }

variable "name_prefix" {
  description = "Standardized prefix for naming resources"
  type        = string
}

# variable "vpc_id" {
#   description = "VPC id"
#   type        = string
# }

# variable "private_subnet_ids" {
#   description = "IDs of the private subnets"
#   type        = list(string)
# }

variable "nlb_arn" {
  description = "ARN of network load balancer"
  type        = string
}

variable "nlb_dns_name" {
  description = "The internal DNS name of the NLB."
  type        = string
}

variable "kms_key_arn" {
  description = "The ARN of the KMS key for CloudWatch Log encryption."
  type        = string
}