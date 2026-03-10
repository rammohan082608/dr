variable "name_prefix" {
  description = "Standardized prefix for naming resources"
  type        = string
}

variable "domain_name" {
  description = "The custom domain name for the API (e.g. api.example.com)"
  type        = string
}

variable "primary_api_id" {
  description = "The ID of the primary API Gateway"
  type        = string
}

variable "primary_api_region" {
  description = "The region of the primary API Gateway"
  type        = string
}

variable "primary_endpoint_url" {
  description = "The invoke URL of the primary API Gateway (used for health checks)"
  type        = string
}

variable "dr_api_id" {
  description = "The ID of the secondary DR API Gateway"
  type        = string
}

variable "dr_api_region" {
  description = "The region of the secondary DR API Gateway"
  type        = string
}
