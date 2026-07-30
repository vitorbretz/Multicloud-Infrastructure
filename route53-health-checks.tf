resource "aws_route53_health_check" "aws_primary" {
  type              = "HTTPS"
  fqdn              = var.dns_config.cloudfront_domain
  port              = 443
  request_interval  = var.dns_config.health_checks.request_interval
  failure_threshold = var.dns_config.health_checks.failure_threshold
  resource_path     = "/"

  tags = merge(
    local.common_tags,
    {
      Name     = "${var.project_name}-aws-health-check"
      Provider = "AWS"
      Type     = "Primary"
    }
  )
}

resource "aws_route53_health_check" "azure_secondary" {
  type              = "HTTPS"
  fqdn              = local.azure_website_endpoint
  port              = 443
  request_interval  = var.dns_config.health_checks.request_interval
  failure_threshold = var.dns_config.health_checks.failure_threshold

  tags = merge(
    local.common_tags,
    {
      Name     = "${var.project_name}-azure-health-check"
      Provider = "Azure"
      Type     = "Secondary"
    }
  )
}
