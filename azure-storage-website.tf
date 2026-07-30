resource "azurerm_storage_account_static_website" "this" {
  storage_account_id = azurerm_storage_account.this.id

  index_document     = var.azure_storage_website.website.index_document
  error_404_document = var.azure_storage_website.website.error_document
}
