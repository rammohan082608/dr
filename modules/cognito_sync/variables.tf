terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      
    }
  }
}

variable "name_prefix" {
  type        = string
  description = "Standardized prefix"
}

variable "dr_user_pool_id" {
  type        = string
  description = "The user pool ID in the DR region"
}

variable "dr_region" {
  type        = string
  description = "The DR AWS region"
}
