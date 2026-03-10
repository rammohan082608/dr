terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      
    }
  }
}

variable "quanum_hub_repo_name" {
  description = "Name of the ECR repository for Quanum Hub"
  type        = string
  default     = "quanum-hub"
}

variable "strand_middleware_repo_name" {
  description = "Name of the ECR repository for Strand Middleware"
  type        = string
  default     = "strand-middleware"
}
