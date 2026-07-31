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

# Health Check for Apex Domain (CloudFront)
resource "aws_route53_health_check" "apex_primary" {
  count = var.dns_config.apex_failover.enabled ? 1 : 0
  
  type              = "HTTPS"
  fqdn              = var.dns_config.cloudfront_domain
  port              = 443
  request_interval  = var.dns_config.health_checks.request_interval
  failure_threshold = var.dns_config.health_checks.failure_threshold
  resource_path     = "/"

  tags = merge(
    local.common_tags,
    {
      Name     = "${var.project_name}-apex-primary-health-check"
      Provider = "AWS"
      Type     = "Primary"
    }
  )
}

# Health Check for Azure Front Door
resource "aws_route53_health_check" "azure_frontdoor" {
  count = var.dns_config.apex_failover.enabled ? 1 : 0
  
  type              = "HTTPS"
  fqdn              = azurerm_cdn_frontdoor_endpoint.this.host_name
  port              = 443
  request_interval  = var.dns_config.health_checks.request_interval
  failure_threshold = var.dns_config.health_checks.failure_threshold
  resource_path     = "/"

  tags = merge(
    local.common_tags,
    {
      Name     = "${var.project_name}-azure-frontdoor-health-check"
      Provider = "Azure"
      Type     = "FrontDoor"
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
