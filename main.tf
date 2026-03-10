terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  required_version = ">= 1.10"

  backend "s3" {
    bucket = "qdm-tf-state"                # Name of your S3 bucket
    key    = "terraform/terraform.tfstate" # Path/name of the state file
    region = "us-east-1"                   # Region of the bucket
  }
}

locals {
  name_prefix    = "quest-proxy"
  name_prefix_dr = "quest-proxy-dr"
  project_name   = "qd-middleware"
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project = local.project_name
    }
  }
}

provider "aws" {
  alias  = "dr"
  region = var.aws_dr_region

  default_tags {
    tags = {
      Project = local.project_name
    }
  }
}

# --- Module: VPC Data ---
# Creates the vpc and subnets with gateways
module "vpc" {
  source = "./modules/vpc"

  name_prefix = local.name_prefix
}

# --- Module: KMS ---
# Creates the encryption key
module "kms" {
  source = "./modules/kms"

  providers = {
    aws    = aws
    aws.dr = aws.dr
  }

  name_prefix = local.name_prefix
}

# --- Module: Cognito ---
# Creates the User Pool and Client
module "cognito" {
  source = "./modules/cognito"

  name_prefix        = local.name_prefix
  kms_key_arn        = module.kms.kms_key_arn
  sync_lambda_arn    = module.cognito_sync.lambda_arn
  enable_sync_lambda = true
}

# --- Module: Cognito Sync (DR) ---
# Creates the Lambda function to sync primary cognito users to DR
module "cognito_sync" {
  source = "./modules/cognito_sync"

  name_prefix     = local.name_prefix
  dr_user_pool_id = module.cognito_dr.cognito_user_pool_id
  dr_region       = var.aws_dr_region
}

# --- Module: DynamoDB ---
# Creates Dynamodb for reconciliation
module "dynamodb" {
  source = "./modules/dynamodb"

  name_prefix    = local.name_prefix
  kms_key_arn    = module.kms.kms_key_arn
  replica_region = var.aws_dr_region
}

# --- Module: API Gateway ---
# Creates the API, /ANY endpoint, authorizer, and ALB integration
module "api_gateway" {
  source = "./modules/api_gateway"

  aws_region            = var.aws_region
  name_prefix           = local.name_prefix
  cognito_user_pool_arn = module.cognito.cognito_pool_arn
  nlb_arn               = module.ecs_processor.nlb_arn
  nlb_dns_name          = module.ecs_processor.nlb_dns_name
  kms_key_arn           = module.kms.kms_key_arn
}

# --- Module: WAF ---
# Creates the WAF ACL with rule groups for Cognito and API Gateway
module "waf" {
  source = "./modules/waf"

  name_prefix           = local.name_prefix
  api_gateway_arn       = module.api_gateway.rest_api_arn
  cognito_user_pool_arn = module.cognito.cognito_pool_arn
  kms_key_arn           = module.kms.kms_key_arn
}

# --- Module: ECS Processor ---
# Creates the ECS Cluster, Task Def, Service, and Auto-Scaling
module "ecs_processor" {
  source = "./modules/ecs_processor"

  aws_region         = var.aws_region
  name_prefix        = local.name_prefix
  ecr_image_uri      = var.middleware_ecr_image_uri
  quest_server_url   = module.mock_quanum_hub.service_url
  vpc_id             = module.vpc.vpc_id
  subnet_ids         = module.vpc.private_subnet_ids
  kms_key_arn        = module.kms.kms_key_arn
  dynamodb_table_arn = module.dynamodb.dynamodb_arn
}

# --- Module: Auditing ---
# Creates CloudTrail and the auth failure alarm
module "auditing" {
  source        = "./modules/auditing"
  kms_key_arn   = module.kms.kms_key_arn
  name_prefix   = local.name_prefix
  s3_bucket_arn = var.s3_bucket_arn
}

# --- Module: App Runner ---
# Creates Mock Quest server
module "mock_quanum_hub" {
  source           = "./modules/app_runner"
  name_prefix      = local.name_prefix
  server_ecr_image = var.quanum_ecr_image_uri
}


# ==========================================
# --- DR Region Resources (us-east-2) ---
# ==========================================

module "vpc_dr" {
  source = "./modules/vpc"
  providers = { aws = aws.dr }

  name_prefix = local.name_prefix_dr
}

module "cognito_dr" {
  source = "./modules/cognito"
  providers = { aws = aws.dr }

  name_prefix = local.name_prefix_dr
  kms_key_arn = module.kms.kms_key_dr_arn
}

module "mock_quanum_hub_dr" {
  source           = "./modules/app_runner"
  providers        = { aws = aws.dr }
  
  name_prefix      = local.name_prefix_dr
  server_ecr_image = var.quanum_ecr_image_uri
}

module "ecs_processor_dr" {
  source = "./modules/ecs_processor"
  providers = { aws = aws.dr }

  aws_region         = var.aws_dr_region
  name_prefix        = local.name_prefix_dr
  ecr_image_uri      = var.middleware_ecr_image_uri
  quest_server_url   = module.mock_quanum_hub_dr.service_url
  vpc_id             = module.vpc_dr.vpc_id
  subnet_ids         = module.vpc_dr.private_subnet_ids
  kms_key_arn        = module.kms.kms_key_dr_arn
  dynamodb_table_arn = replace(module.dynamodb.dynamodb_arn, var.aws_region, var.aws_dr_region)
}

module "api_gateway_dr" {
  source = "./modules/api_gateway"
  providers = { aws = aws.dr }

  aws_region            = var.aws_dr_region
  name_prefix           = local.name_prefix_dr
  cognito_user_pool_arn = module.cognito_dr.cognito_pool_arn
  nlb_arn               = module.ecs_processor_dr.nlb_arn
  nlb_dns_name          = module.ecs_processor_dr.nlb_dns_name
  kms_key_arn           = module.kms.kms_key_dr_arn
}

module "waf_dr" {
  source = "./modules/waf"
  providers = { aws = aws.dr }

  name_prefix           = local.name_prefix_dr
  api_gateway_arn       = module.api_gateway_dr.rest_api_arn
  cognito_user_pool_arn = module.cognito_dr.cognito_pool_arn
  kms_key_arn           = module.kms.kms_key_dr_arn
}

# --- Module: Route53 Failover ---
# Configures dns routing to primary with failover to DR
module "route53_failover" {
  source = "./modules/route53"

  name_prefix          = local.name_prefix
  domain_name          = var.custom_domain_name
  
  primary_api_id       = module.api_gateway.rest_api_id
  primary_api_region   = var.aws_region
  primary_endpoint_url = module.api_gateway.apigateway_invoke_url2
  
  dr_api_id            = module.api_gateway_dr.rest_api_id
  dr_api_region        = var.aws_dr_region
}