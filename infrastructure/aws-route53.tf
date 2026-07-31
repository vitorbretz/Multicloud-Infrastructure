# ==============================================================================
# AWS ROUTE53 DNS RESOURCES  
# ==============================================================================
# DNS zone, records, and health checks for multicloud failover
# Author: Vitor
# Created: 2026-07-31
# ==============================================================================

# Route53 Hosted Zone
resource "aws_route53_zone" "this" {
  name = var.dns_config.domain_name

  tags = merge(
    local.common_tags,
    {
      Name     = var.dns_config.domain_name
      Type     = "PublicHostedZone"
      Service  = "Route53"
      Purpose  = "DNS Failover Management"
    }
  )
}

# ==============================================================================
# DATA SOURCES FOR DYNAMIC IP RESOLUTION
# ==============================================================================

# Get Azure Front Door IP addresses dynamically
data "dns_a_record_set" "azure_frontdoor" {
  count = var.dns_config.apex_failover.enabled ? 1 : 0
  host  = azurerm_cdn_frontdoor_endpoint.this.host_name
}

# ==============================================================================
# APEX DOMAIN RECORDS (cloud.flog.br)  
# ==============================================================================

# PRIMARY record for apex domain - Routes to CloudFront
resource "aws_route53_record" "apex_primary" {
  count = var.dns_config.apex_failover.enabled ? 1 : 0
  
  zone_id = aws_route53_zone.this.zone_id
  name    = var.dns_config.domain_name
  type    = "A"

  alias {
    name                   = var.dns_config.cloudfront_domain
    zone_id                = var.dns_config.cloudfront_zone_id
    evaluate_target_health = true
  }

  failover_routing_policy {
    type = "PRIMARY"
  }

  set_identifier  = "apex-primary"
  health_check_id = aws_route53_health_check.apex_primary[0].id
}

# SECONDARY record for apex domain - Routes to Azure Front Door
resource "aws_route53_record" "apex_secondary" {
  count = var.dns_config.apex_failover.enabled ? 1 : 0
  
  zone_id = aws_route53_zone.this.zone_id
  name    = var.dns_config.domain_name
  type    = "A"

  # Using TTL with Front Door's resolved IP
  records = [data.dns_a_record_set.azure_frontdoor[0].addrs[0]]
  ttl     = 300

  failover_routing_policy {
    type = "SECONDARY"
  }

  set_identifier  = "apex-secondary"
  health_check_id = aws_route53_health_check.azure_frontdoor[0].id
}

# ==============================================================================
# WWW SUBDOMAIN RECORDS (www.cloud.flog.br)
# ==============================================================================

# PRIMARY record for www subdomain - Routes to CloudFront
resource "aws_route53_record" "primary" {
  zone_id = aws_route53_zone.this.zone_id
  name    = "www.${var.dns_config.domain_name}"
  type    = "CNAME"

  records = [var.dns_config.cloudfront_domain]
  ttl     = 60

  failover_routing_policy {
    type = "PRIMARY"
  }

  set_identifier  = "www-primary"
  health_check_id = aws_route53_health_check.aws_primary.id
}

# SECONDARY failover record - Azure Storage Static Website
resource "aws_route53_record" "secondary" {
  zone_id = aws_route53_zone.this.zone_id
  name    = "www.${var.dns_config.domain_name}"
  type    = "CNAME"

  records = [local.azure_website_endpoint]
  ttl     = 300

  failover_routing_policy {
    type = "SECONDARY"
  }

  set_identifier  = "secondary"
  health_check_id = aws_route53_health_check.azure_secondary.id
}

# ==============================================================================
# HEALTH CHECKS
# ==============================================================================

# Health Check for AWS CloudFront (www subdomain)
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
      Service  = "CloudFront"
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
      Service  = "CloudFront"
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
      Service  = "AzureFrontDoor"
    }
  )
}

# Health Check for Azure Storage (www subdomain failover)
resource "aws_route53_health_check" "azure_secondary" {
  type              = "HTTPS"
  fqdn              = local.azure_website_endpoint
  port              = 443
  request_interval  = var.dns_config.health_checks.request_interval
  failure_threshold = var.dns_config.health_checks.failure_threshold
  resource_path     = "/"

  tags = merge(
    local.common_tags,
    {
      Name     = "${var.project_name}-azure-health-check"
      Provider = "Azure"
      Type     = "Secondary"
      Service  = "StorageWebsite"
    }
  )
}