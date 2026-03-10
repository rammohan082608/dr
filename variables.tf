variable "aws_region" {
  description = "Primary region for deployment"
  type        = string
  default     = "us-east-1"
}

variable "aws_dr_region" {
  description = "Disaster Recovery region for deployment"
  type        = string
  default     = "us-east-2"
}

variable "middleware_ecr_image_uri" {
  description = "The ECR image URI for the middleware"
  type        = string
  default     = "905906650285.dkr.ecr.us-east-1.amazonaws.com/strand-middleware:latest"
}

variable "quanum_ecr_image_uri" {
  description = "The ECR image URI for the mock quanum-hub"
  type        = string
  default     = "905906650285.dkr.ecr.us-east-1.amazonaws.com/quanum-hub:latest"
}

variable "s3_bucket_arn" {
  description = "The S3 bucket run for logs and cloudtrail"
  type        = string
  default     = "arn:aws:s3:::qdm-tf-state"
}

variable "custom_domain_name" {
  description = "The custom domain name for the API (e.g. api.quest-middleware.com) to use with Route 53."
  type        = string
  default     = "api.quest-middleware.com" 
}
