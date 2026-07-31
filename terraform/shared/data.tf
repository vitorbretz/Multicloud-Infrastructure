data "azurerm_storage_container" "web" {
  name               = "$web"
  storage_account_id = azurerm_storage_account.this.id

  depends_on = [azurerm_storage_account_static_website.this]
}

# Data source to resolve Azure Front Door IP addresses
data "dns_a_record_set" "azure_frontdoor" {
  count = var.dns_config.apex_failover.enabled ? 1 : 0
  host  = azurerm_cdn_frontdoor_endpoint.this.host_name
  
  depends_on = [azurerm_cdn_frontdoor_endpoint.this]
}
