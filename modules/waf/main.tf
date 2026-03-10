# Custom Log Group
resource "aws_cloudwatch_log_group" "waf_logs" {
  name              = "aws-waf-logs-${var.name_prefix}"
  kms_key_id        = var.kms_key_arn
  retention_in_days = 7
}

# Partner IP Set
resource "aws_wafv2_ip_set" "partners_ipv4" {
  name               = "${var.name_prefix}-whitelist-ipv4"
  scope              = "REGIONAL"
  ip_address_version = "IPV4"
  addresses          = ["122.172.82.89/32"]
}

resource "aws_wafv2_ip_set" "partners_ipv6" {
  name               = "${var.name_prefix}-whitelist-ipv6"
  scope              = "REGIONAL"
  ip_address_version = "IPV6"
  addresses          = ["2401:4900:1cbc:e5f:7928:9a4e:d328:7605/128"]
}

# Web ACL with 2 rule groups
resource "aws_wafv2_web_acl" "hl7_security" {
  name        = "${var.name_prefix}-hl7-security-acl"
  scope       = "REGIONAL"
  description = "Unified WAF for API Gateway + Cognito"

  default_action {
    block {}
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "waf-metrics"
    sampled_requests_enabled   = true
  }

  # Goal: Block IPs exceeding the traffic threshold.
  rule {
    name     = "API-Rate-Limit"
    priority = 2
    action {
      block {}
    }
    statement {
      rate_based_statement {
        limit              = 5000
        aggregate_key_type = "IP"
      }
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "APIRateLimitMetric"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "API-Partner-Allow"
    priority = 1
    action {
      allow {}
    }
    statement {
      or_statement {
        statement {
          ip_set_reference_statement {
            arn = aws_wafv2_ip_set.partners_ipv4.arn
          }
        }
        statement {
          ip_set_reference_statement {
            arn = aws_wafv2_ip_set.partners_ipv6.arn
          }
        }
      }
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "PartnerAllowMetric"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "AWS-Common-Rules"
    priority = 10
    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        vendor_name = "AWS"
        name        = "AWSManagedRulesCommonRuleSet"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      sampled_requests_enabled   = true
      metric_name                = "AWSCommonRules"
    }
  }

  rule {
    name     = "AWS-KnownBadInputs"
    priority = 15
    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        vendor_name = "AWS"
        name        = "AWSManagedRulesKnownBadInputsRuleSet"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      sampled_requests_enabled   = true
      metric_name                = "AWSKnownBadInputs"
    }
  }

  # rule {
  #   name     = "AWS-Anti-DDoS"
  #   priority = 31
  #   override_action {
  #     none {}
  #   }

  #   statement {
  #     managed_rule_group_statement {
  #       vendor_name = "AWS"
  #       name        = "AWSManagedRulesAntiDDoSRuleSet"
  #     }
  #   }

  #   visibility_config {
  #     cloudwatch_metrics_enabled = true
  #     sampled_requests_enabled   = true
  #     metric_name                = "AWSAntiDDoS"
  #   }
  # }

  # rule {
  #   name     = "AWS-XSS-Protection"
  #   priority = 12

  #   override_action {
  #     none {}
  #   }

  #   statement {
  #     managed_rule_group_statement {
  #       name        = "AWSManagedRulesXSSRuleSet"
  #       vendor_name = "AWS"
  #     }
  #   }

  #   visibility_config {
  #     cloudwatch_metrics_enabled = true
  #     metric_name                = "AWS-XSS-Protection"
  #     sampled_requests_enabled   = true
  #   }
  # }

  rule {
    name     = "AWS-SQLi-Protection"
    priority = 13

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesSQLiRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWS-SQLi-Protection"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "Allow-Approved-Countries"
    priority = 30

    action {
      allow {}
    }

    statement {
      geo_match_statement {
        country_codes = [
          "US", # United States
          "CA", # Canada
          "IN"  # India
        ]
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AllowApprovedCountries"
      sampled_requests_enabled   = true
    }
  }
}

# Associate WAF with API Gateway
resource "aws_wafv2_web_acl_association" "api_gateway" {
  resource_arn = var.api_gateway_arn
  web_acl_arn  = aws_wafv2_web_acl.hl7_security.arn
}

# Associate WAF with Cognito User Pool
resource "aws_wafv2_web_acl_association" "cognito" {
  resource_arn = var.cognito_user_pool_arn
  web_acl_arn  = aws_wafv2_web_acl.hl7_security.arn
}

# Enable logging to CloudWatch
resource "aws_wafv2_web_acl_logging_configuration" "logging" {
  resource_arn            = aws_wafv2_web_acl.hl7_security.arn
  log_destination_configs = ["${aws_cloudwatch_log_group.waf_logs.arn}:*"]
}
