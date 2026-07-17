provider "aws" {
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
  region     = "us-east-1"
}

provider "azurerm" {
  features {}

  client_id       = var.azure_client_id
  client_secret   = var.azure_client_secret
  subscription_id = var.azure_subscription_id
  tenant_id       = var.azure_tenant_id
}

resource "aws_s3_bucket" "weather_app" {
  bucket = "multicloud-weather-app-vitor-2026"

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_website_configuration" "website" {
  bucket = aws_s3_bucket.weather_app.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}

resource "aws_s3_bucket_public_access_block" "public_access" {
  bucket                  = aws_s3_bucket.weather_app.id
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# Upload website files to the S3 bucket
resource "aws_s3_object" "website_index" {
  bucket = aws_s3_bucket.weather_app.id
  key    = "index.html"
  source = "website/index.html"
  content_type = "text/html"
}

resource "aws_s3_object" "website_style" {
  bucket = aws_s3_bucket.weather_app.id
  key    = "styles.css"
  source = "website/styles.css"
  content_type = "text/css"
}

resource "aws_s3_object" "website_script" {
  bucket = aws_s3_bucket.weather_app.id
  key    = "script.js"
  source = "website/script.js"
  content_type = "application/javascript"
}

# Upload assets (images) to the S3 bucket
resource "aws_s3_object" "website_assets" {
  for_each = fileset("website/assets", "*")
  bucket   = aws_s3_bucket.weather_app.id
  key      = "assets/${each.value}"
  source   = "website/assets/${each.value}"
}

# Add a bucket policy to allow public read access
resource "aws_s3_bucket_policy" "bucket_policy" {
  bucket = aws_s3_bucket.weather_app.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid       = "PublicReadGetObject",
        Effect    = "Allow",
        Principal = "*",
        Action    = "s3:GetObject",
        Resource  = "arn:aws:s3:::${aws_s3_bucket.weather_app.id}/*"
      },
      {
        Sid       = "CloudFrontLogsWrite",
        Effect    = "Allow",
        Principal = {
          Service = "cloudfront.amazonaws.com"
        },
        Action    = "s3:PutObject",
        Resource  = "arn:aws:s3:::${aws_s3_bucket.weather_app.id}/cloudfront-logs/*"
      }
    ]
  })
}

resource "azurerm_resource_group" "rg" {
  name     = "rg-static-website"
  location = "East US"
}

resource "azurerm_storage_account" "storage" {
  name                     = "myaccounttostorageweb"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location

  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"
}

resource "azurerm_storage_account_static_website" "website" {
  storage_account_id = azurerm_storage_account.storage.id

  index_document = "index.html"
  error_404_document = "error.html"
}