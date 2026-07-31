# ==============================================================================
# AZURE STORAGE RESOURCES
# ==============================================================================
# Azure Resource Group, Storage Account, and Static Website configuration
# Author: Vitor
# Created: 2026-07-31
# ==============================================================================

# Azure Resource Group
resource "azurerm_resource_group" "this" {
  name     = var.azure_storage_website.resource_group_name
  location = var.azure_location

  tags = merge(
    local.common_tags,
    {
      Name        = var.azure_storage_website.resource_group_name
      Provider    = "Azure" 
      Service     = "ResourceGroup"
      Purpose     = "Static Website Hosting"
    }
  )
}

# Azure Storage Account
resource "azurerm_storage_account" "this" {
  name                     = var.azure_storage_website.storage_account_name
  resource_group_name      = azurerm_resource_group.this.name
  location                 = azurerm_resource_group.this.location
  account_tier             = var.azure_storage_website.account_tier
  account_replication_type = var.azure_storage_website.replication_type
  account_kind             = "StorageV2"
  
  # Enable HTTP access for Azure failover (required for custom domains without CDN)
  https_traffic_only_enabled = false

  # Static website configuration
  static_website {
    index_document     = var.azure_storage_website.website.index_document
    error_404_document = var.azure_storage_website.website.error_document
  }

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
      Name        = var.azure_storage_website.storage_account_name
      Type        = "StaticWebsite"
      Provider    = "Azure"
      Service     = "StorageAccount" 
      Purpose     = "Secondary Website Hosting"
    }
  )
}