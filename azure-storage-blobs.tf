resource "azurerm_storage_blob" "html" {
  name                 = local.website_files.html.key
  storage_container_id = data.azurerm_storage_container.web.id
  type                 = "Block"
  content_type         = local.website_files.html.content_type
  source               = local.website_files.html.source
  cache_control        = var.azure_storage_website.cache_control.html
}

resource "azurerm_storage_blob" "css" {
  name                 = local.website_files.css.key
  storage_container_id = data.azurerm_storage_container.web.id
  type                 = "Block"
  content_type         = local.website_files.css.content_type
  source               = local.website_files.css.source
  cache_control        = var.azure_storage_website.cache_control.css
}

resource "azurerm_storage_blob" "js" {
  name                 = local.website_files.js.key
  storage_container_id = data.azurerm_storage_container.web.id
  type                 = "Block"
  content_type         = local.website_files.js.content_type
  source               = local.website_files.js.source
  cache_control        = var.azure_storage_website.cache_control.js
}

resource "azurerm_storage_blob" "assets" {
  for_each = fileset("${var.website_source_path}/assets", "**/*")

  name                 = "assets/${each.value}"
  storage_container_id = data.azurerm_storage_container.web.id
  type                 = "Block"
  content_type = lookup(
    local.content_type_mapping,
    element(split(".", each.value), length(split(".", each.value)) - 1),
    "application/octet-stream"
  )
  source        = "${var.website_source_path}/assets/${each.value}"
  cache_control = var.azure_storage_website.cache_control.assets
}
