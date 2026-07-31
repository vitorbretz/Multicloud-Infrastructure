resource "azurerm_resource_group" "this" {
  name     = var.azure_storage_website.resource_group_name
  location = var.azure_location

  tags = merge(
    local.common_tags,
    {
      Name = var.azure_storage_website.resource_group_name
    }
  )
}
