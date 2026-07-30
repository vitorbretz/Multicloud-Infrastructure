# AWS S3 Outputs
output "aws_s3_bucket_id" {
  description = "The ID of the AWS S3 bucket"
  value       = aws_s3_bucket.this.id
}

output "aws_s3_bucket_arn" {
  description = "The ARN of the AWS S3 bucket"
  value       = aws_s3_bucket.this.arn
}

output "aws_s3_website_endpoint" {
  description = "The website endpoint of the AWS S3 bucket"
  value       = aws_s3_bucket_website_configuration.this.website_endpoint
}

output "aws_s3_website_domain" {
  description = "The domain name of the AWS S3 website"
  value       = aws_s3_bucket_website_configuration.this.website_domain
}

# Azure Outputs
output "azure_resource_group_id" {
  description = "The ID of the Azure Resource Group"
  value       = azurerm_resource_group.this.id
}

output "azure_storage_account_id" {
  description = "The ID of the Azure Storage Account"
  value       = azurerm_storage_account.this.id
}

output "azure_storage_account_name" {
  description = "The name of the Azure Storage Account"
  value       = azurerm_storage_account.this.name
}

output "azure_website_endpoint" {
  description = "The primary endpoint of the Azure static website"
  value       = "https://${local.azure_website_endpoint}"
}

output "azure_website_host" {
  description = "The hostname of the Azure static website"
  value       = local.azure_website_endpoint
}

# Route53 DNS Outputs
output "route53_zone_id" {
  description = "The ID of the Route53 hosted zone"
  value       = aws_route53_zone.this.zone_id
}

output "route53_zone_name_servers" {
  description = "The name servers for the Route53 hosted zone"
  value       = aws_route53_zone.this.name_servers
}

output "route53_primary_record_fqdn" {
  description = "The FQDN of the primary DNS record"
  value       = aws_route53_record.primary.fqdn
}

output "route53_secondary_record_fqdn" {
  description = "The FQDN of the secondary DNS record"
  value       = aws_route53_record.secondary.fqdn
}

# Health Checks Outputs
output "aws_health_check_id" {
  description = "The ID of the AWS health check"
  value       = aws_route53_health_check.aws_primary.id
}

output "azure_health_check_id" {
  description = "The ID of the Azure health check"
  value       = aws_route53_health_check.azure_secondary.id
}

# Website URLs
output "website_urls" {
  description = "All accessible URLs for the weather application"
  value = {
    aws_s3_direct        = "http://${aws_s3_bucket_website_configuration.this.website_endpoint}"
    aws_cloudfront       = "https://${var.dns_config.cloudfront_domain}"
    aws_custom_domain    = "https://${var.dns_config.domain_name}"
    azure_direct         = "https://${local.azure_website_endpoint}"
    azure_failover_cname = "https://www.${var.dns_config.domain_name}"
  }
}
