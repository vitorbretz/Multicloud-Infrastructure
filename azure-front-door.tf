# Azure Front Door Configuration for Apex Domain Support
# This module adds Front Door as intermediary between DNS and Azure Storage
# to enable apex domain (cloud.flog.br) support with failover capabilities

# Front Door Profile
resource "azurerm_cdn_frontdoor_profile" "this" {
  name                = "${var.project_name}-${var.environment}-fd"
  resource_group_name = azurerm_resource_group.this.name
  sku_name           = "Standard_AzureFrontDoor"

  tags = merge(
    local.common_tags,
    {
      Name        = "${var.project_name}-${var.environment}-frontdoor"
      Component   = "frontdoor"
      Purpose     = "apex-domain-support"
      Description = "Azure Front Door for apex domain and failover support"
    }
  )
}

# Front Door Endpoint
resource "azurerm_cdn_frontdoor_endpoint" "this" {
  name                     = "${var.project_name}-${var.environment}-endpoint"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.this.id

  tags = merge(
    local.common_tags,
    {
      Name      = "${var.project_name}-${var.environment}-endpoint"
      Component = "frontdoor"
    }
  )
}

# Origin Group
resource "azurerm_cdn_frontdoor_origin_group" "this" {
  name                     = "${var.project_name}-storage-origin-group"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.this.id
  session_affinity_enabled = false

  load_balancing {
    sample_size                 = 4
    successful_samples_required = 3
  }

  health_probe {
    path                = "/"
    request_type        = "HEAD"
    protocol            = "Https"
    interval_in_seconds = 100
  }
}

# Origin - Azure Storage Static Website
resource "azurerm_cdn_frontdoor_origin" "azure_storage" {
  name                          = "${var.project_name}-storage-origin"
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.this.id
  
  enabled                        = true
  host_name                     = azurerm_storage_account.this.primary_web_host
  http_port                     = 80
  https_port                    = 443
  origin_host_header            = azurerm_storage_account.this.primary_web_host
  priority                      = 1
  weight                        = 1000
  certificate_name_check_enabled = true
}

# Route Configuration
resource "azurerm_cdn_frontdoor_route" "this" {
  name                          = "${var.project_name}-route"
  cdn_frontdoor_endpoint_id     = azurerm_cdn_frontdoor_endpoint.this.id
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.this.id
  cdn_frontdoor_origin_ids      = [azurerm_cdn_frontdoor_origin.azure_storage.id]
  cdn_frontdoor_custom_domain_ids = [azurerm_cdn_frontdoor_custom_domain.apex_domain.id]

  supported_protocols    = ["Http", "Https"]
  patterns_to_match     = ["/*"]
  forwarding_protocol   = "HttpsOnly"
  link_to_default_domain = true
  https_redirect_enabled = true

  cache {
    query_string_caching_behavior = "IgnoreSpecifiedQueryStrings"
    query_strings                = ["utm_source", "utm_medium", "utm_campaign"]
    compression_enabled          = true
    content_types_to_compress = [
      "application/eot",
      "application/font",
      "application/font-sfnt",
      "application/javascript", 
      "application/json",
      "application/opentype",
      "application/otf",
      "application/pkcs7-mime",
      "application/truetype",
      "application/ttf",
      "application/vnd.ms-fontobject",
      "application/xhtml+xml",
      "application/xml",
      "application/xml+rss",
      "application/x-font-opentype",
      "application/x-font-truetype",
      "application/x-font-ttf",
      "application/x-httpd-cgi",
      "application/x-javascript",
      "application/x-mpegurl",
      "application/x-opentype",
      "application/x-otf",
      "application/x-perl",
      "application/x-ttf",
      "font/eot",
      "font/ttf",
      "font/otf",
      "font/opentype",
      "image/svg+xml",
      "text/css",
      "text/csv",
      "text/html",
      "text/javascript",
      "text/js",
      "text/plain",
      "text/richtext",
      "text/tab-separated-values",
      "text/xml",
      "text/x-script",
      "text/x-component",
      "text/x-java-source"
    ]
  }
}

# Custom Domain for Apex
resource "azurerm_cdn_frontdoor_custom_domain" "apex_domain" {
  name                     = replace(var.dns_config.domain_name, ".", "-")
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.this.id
  host_name               = var.dns_config.domain_name

  tls {
    certificate_type    = "ManagedCertificate"
    minimum_version     = "TLS12"
  }
}

# Custom Domain Association is handled by the route configuration

# Security Policy (optional but recommended)
resource "azurerm_cdn_frontdoor_security_policy" "this" {
  name                     = "${var.project_name}-security-policy"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.this.id

  security_policies {
    firewall {
      cdn_frontdoor_firewall_policy_id = azurerm_cdn_frontdoor_firewall_policy.this.id
      
      association {
        domain {
          cdn_frontdoor_domain_id = azurerm_cdn_frontdoor_custom_domain.apex_domain.id
        }
        patterns_to_match = ["/*"]
      }
    }
  }
}

# Web Application Firewall Policy
resource "azurerm_cdn_frontdoor_firewall_policy" "this" {
  name                              = "${replace(var.project_name, "-", "")}${var.environment}waf"
  resource_group_name               = azurerm_resource_group.this.name
  sku_name                         = azurerm_cdn_frontdoor_profile.this.sku_name
  enabled                          = true
  mode                             = "Prevention"
  redirect_url                     = "https://www.${var.dns_config.domain_name}"
  custom_block_response_status_code = 403
  custom_block_response_body        = base64encode("Access Denied")

  tags = merge(
    local.common_tags,
    {
      Name      = "${var.project_name}-${var.environment}-waf"
      Component = "security"
    }
  )
}