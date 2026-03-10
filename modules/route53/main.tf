resource "aws_route53_zone" "main" {
  name = join(".", slice(split(".", var.domain_name), 1, length(split(".", var.domain_name))))
  
  # For the sake of this demo/testing, we will create the zone if it doesn't exist
  # In a real environment, you'd likely use a data source targeting an existing verified domain.
}

resource "aws_route53_health_check" "primary_health_check" {
  # Extract just the hostname from the invoke URL (e.g. https://abc.execute-api.us-east-1.amazonaws.com/api)
  fqdn              = "${var.primary_api_id}.execute-api.${var.primary_api_region}.amazonaws.com"
  port              = 443
  type              = "HTTPS"
  resource_path     = "/api/v1/health" # Assuming a health endpoint exists
  failure_threshold = "3"
  request_interval  = "30"

  tags = {
    Name = "${var.name_prefix}-primary-health-check"
  }
}

resource "aws_route53_record" "primary_api" {
  zone_id = aws_route53_zone.main.zone_id
  name    = var.domain_name
  type    = "CNAME"
  ttl     = 60

  failover_routing_policy {
    type = "PRIMARY"
  }

  set_identifier  = "Primary"
  health_check_id = aws_route53_health_check.primary_health_check.id

  # Assuming custom domain name created in API gateway, point to the regional domain name
  # In a full setup, you'd create `aws_api_gateway_domain_name` and pass its regional_domain_name here
  records = ["${var.primary_api_id}.execute-api.${var.primary_api_region}.amazonaws.com"]
}

resource "aws_route53_record" "secondary_api" {
  zone_id = aws_route53_zone.main.zone_id
  name    = var.domain_name
  type    = "CNAME"
  ttl     = 60

  failover_routing_policy {
    type = "SECONDARY"
  }

  set_identifier = "Secondary"

  records = ["${var.dr_api_id}.execute-api.${var.dr_api_region}.amazonaws.com"]
}
