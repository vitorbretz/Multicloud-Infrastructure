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

# SECONDARY record for apex domain - Routes to Azure Front Door
# NOTE: We need to use A records with Front Door's IP addresses
# This requires data source to get Front Door's IPs dynamically
resource "aws_route53_record" "apex_secondary" {
  count = var.dns_config.apex_failover.enabled ? 1 : 0
  
  zone_id = aws_route53_zone.this.zone_id
  name    = var.dns_config.domain_name
  type    = "A"

  # Using TTL instead of alias for Front Door
  # Front Door IPs need to be resolved dynamically
  records = [data.dns_a_record_set.azure_frontdoor[0].addrs[0]]
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

# SECONDARY failover record - Azure Storage Static Website
# NOTE: Azure Storage does not support custom domains (CNAME) without Azure CDN
# During failover, users will be redirected but should access via native Azure domain
# This is a known limitation documented in FAILOVER-GUIDE.md
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
