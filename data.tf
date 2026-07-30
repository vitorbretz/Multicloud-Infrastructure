data "azurerm_storage_container" "web" {
  name               = "$web"
  storage_account_id = azurerm_storage_account.this.id

  depends_on = [azurerm_storage_account_static_website.this]
}
