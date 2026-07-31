# ==============================================================================
# WEBSITE DEPLOYMENT RESOURCES
# ==============================================================================
# Upload website files to both AWS S3 and Azure Storage
# Author: Vitor
# Created: 2026-07-31
# ==============================================================================

# ==============================================================================
# AWS S3 OBJECTS
# ==============================================================================

# Upload HTML file to S3
resource "aws_s3_object" "html" {
  bucket       = aws_s3_bucket.this.id
  key          = local.website_files.html.key
  source       = local.website_files.html.source
  content_type = local.website_files.html.content_type
  etag         = filemd5(local.website_files.html.source)

  tags = merge(
    local.common_tags,
    {
      Name     = local.website_files.html.key
      Type     = "HTML"
      Provider = "AWS"
    }
  )
}

# Upload CSS file to S3
resource "aws_s3_object" "css" {
  bucket       = aws_s3_bucket.this.id
  key          = local.website_files.css.key
  source       = local.website_files.css.source
  content_type = local.website_files.css.content_type
  etag         = filemd5(local.website_files.css.source)

  tags = merge(
    local.common_tags,
    {
      Name     = local.website_files.css.key
      Type     = "CSS"
      Provider = "AWS"
    }
  )
}

# Upload JavaScript file to S3
resource "aws_s3_object" "js" {
  bucket       = aws_s3_bucket.this.id
  key          = local.website_files.js.key
  source       = local.website_files.js.source
  content_type = local.website_files.js.content_type
  etag         = filemd5(local.website_files.js.source)

  tags = merge(
    local.common_tags,
    {
      Name     = local.website_files.js.key
      Type     = "JavaScript" 
      Provider = "AWS"
    }
  )
}

# Upload asset files to S3
resource "aws_s3_object" "assets" {
  for_each = fileset("${var.website_source_path}/assets", "*")

  bucket = aws_s3_bucket.this.id
  key    = "assets/${each.value}"
  source = "${var.website_source_path}/assets/${each.value}"
  content_type = lookup(
    local.content_type_mapping,
    element(split(".", each.value), length(split(".", each.value)) - 1),
    "application/octet-stream"
  )
  etag = filemd5("${var.website_source_path}/assets/${each.value}")

  tags = merge(
    local.common_tags,
    {
      Name     = each.value
      Type     = "Asset"
      Provider = "AWS"
    }
  )
}

# ==============================================================================
# AZURE STORAGE DATA SOURCES
# ==============================================================================

# Get the $web container created by static website
data "azurerm_storage_container" "web" {
  name                 = "$web"
  storage_account_name = azurerm_storage_account.this.name

  depends_on = [azurerm_storage_account.this]
}

# ==============================================================================
# AZURE STORAGE BLOBS
# ==============================================================================

# Upload HTML file to Azure Storage
resource "azurerm_storage_blob" "html" {
  name                 = local.website_files.html.key
  storage_container_id = data.azurerm_storage_container.web.id
  type                 = "Block"
  content_type         = local.website_files.html.content_type
  source               = local.website_files.html.source
  cache_control        = var.azure_storage_website.cache_control.html

  depends_on = [azurerm_storage_account.this]
}

# Upload CSS file to Azure Storage
resource "azurerm_storage_blob" "css" {
  name                 = local.website_files.css.key
  storage_container_id = data.azurerm_storage_container.web.id
  type                 = "Block"
  content_type         = local.website_files.css.content_type
  source               = local.website_files.css.source
  cache_control        = var.azure_storage_website.cache_control.css

  depends_on = [azurerm_storage_account.this]
}

# Upload JavaScript file to Azure Storage
resource "azurerm_storage_blob" "js" {
  name                 = local.website_files.js.key
  storage_container_id = data.azurerm_storage_container.web.id
  type                 = "Block"
  content_type         = local.website_files.js.content_type
  source               = local.website_files.js.source
  cache_control        = var.azure_storage_website.cache_control.js

  depends_on = [azurerm_storage_account.this]
}

# Upload asset files to Azure Storage
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

  depends_on = [azurerm_storage_account.this]
}