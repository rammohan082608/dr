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

variable "name_prefix" {
  description = "Standardized prefix for naming resources"
  type        = string
}

variable "ecr_image_uri" {
  description = "The full URI of the ECR image for the processor task."
  type        = string
}

variable "quest_server_url" {
  description = "The URL of the client API server that ECS will call."
  type        = string
}

variable "vpc_id" {
  description = "The ID of the VPC to deploy ECS in."
  type        = string
}

variable "subnet_ids" {
  description = "A list of subnet IDs for the ECS tasks."
  type        = list(string)
}

variable "kms_key_arn" {
  description = "The ARN of the KMS key for CloudWatch Log encryption."
  type        = string
}

variable "dynamodb_table_arn" {
  description = "ARN of the reconcialiation dynamodb table"
  type        = string
}
