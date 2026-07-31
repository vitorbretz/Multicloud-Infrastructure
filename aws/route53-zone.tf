resource "aws_route53_zone" "this" {
  name = var.dns_config.domain_name

  tags = merge(
    local.common_tags,
    {
      Name = var.dns_config.domain_name
      Type = "PublicHostedZone"
    }
  )
}
