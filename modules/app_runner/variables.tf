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

variable "server_ecr_image" {
  description = "The ECR image URI for the mock quanum-hub"
  type        = string
}