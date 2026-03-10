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