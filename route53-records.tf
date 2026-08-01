# ====================================
# APEX DOMAIN RECORDS (cloud.flog.br)  
# ====================================

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

# SECONDARY record for apex domain - Routes to Azure Front Door endpoint directly
# Using A record with AFD IP since CNAME not allowed at apex
resource "aws_route53_record" "apex_secondary" {
  count = var.dns_config.apex_failover.enabled ? 1 : 0
  
  zone_id = aws_route53_zone.this.zone_id
  name    = var.dns_config.domain_name
  type    = "A"

  # Point directly to Azure Front Door IP address
  records = ["150.171.110.39"]
  ttl     = 300

  failover_routing_policy {
    type = "SECONDARY"
  }

  set_identifier  = "apex-secondary"
  health_check_id = aws_route53_health_check.azure_frontdoor[0].id
}

# ====================================
# WWW SUBDOMAIN RECORDS (www.cloud.flog.br)
# ====================================

# PRIMARY record for www subdomain - Routes to CloudFront (existing functionality)
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

# SECONDARY failover record - Azure Front Door endpoint directly
# Temporary fix: using working AFD endpoint instead of storage endpoint
resource "aws_route53_record" "secondary" {
  zone_id = aws_route53_zone.this.zone_id
  name    = "www.${var.dns_config.domain_name}"
  type    = "CNAME"

  records = ["multicloud-weather-app-prod-endpoint-bfbkcmbvbpd6eea7.z02.azurefd.net"]
  ttl     = 300

  failover_routing_policy {
    type = "SECONDARY"
  }

  set_identifier  = "secondary"
  health_check_id = aws_route53_health_check.azure_secondary.id
}
