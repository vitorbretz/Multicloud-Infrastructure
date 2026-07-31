resource "azurerm_storage_account" "this" {
  name                     = var.azure_storage_website.storage_account_name
  resource_group_name      = azurerm_resource_group.this.name
  location                 = azurerm_resource_group.this.location
  account_tier             = var.azure_storage_website.account_tier
  account_replication_type = var.azure_storage_website.replication_type
  account_kind             = "StorageV2"
  
  # Enable HTTP access for Azure failover (required for custom domains without CDN)
  https_traffic_only_enabled = false

  blob_properties {
    cors_rule {
      allowed_headers    = var.azure_storage_website.cors.allowed_headers
      allowed_methods    = var.azure_storage_website.cors.allowed_methods
      allowed_origins    = var.azure_storage_website.cors.allowed_origins
      exposed_headers    = var.azure_storage_website.cors.exposed_headers
      max_age_in_seconds = var.azure_storage_website.cors.max_age_in_seconds
    }
  }

  tags = merge(
    local.common_tags,
    {
      Name = var.azure_storage_website.storage_account_name
      Type = "StaticWebsite"
    }
  )
}
