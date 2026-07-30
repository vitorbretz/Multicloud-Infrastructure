resource "aws_route53_record" "primary" {
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

  set_identifier  = "primary"
  health_check_id = aws_route53_health_check.aws_primary.id
}

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
