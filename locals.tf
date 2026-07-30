locals {
  # Common tags applied to all resources
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    Owner       = var.owner
    ManagedBy   = "Terraform"
    CreatedAt   = "2026-07-30"
  }

  # Website file mappings
  website_files = {
    html = {
      key          = "index.html"
      source       = "${var.website_source_path}/index.html"
      content_type = "text/html"
    }
    css = {
      key          = "styles.css"
      source       = "${var.website_source_path}/styles.css"
      content_type = "text/css"
    }
    js = {
      key          = "script.js"
      source       = "${var.website_source_path}/script.js"
      content_type = "application/javascript"
    }
  }

  # Content type mapping for assets
  content_type_mapping = {
    "png"  = "image/png"
    "jpg"  = "image/jpeg"
    "jpeg" = "image/jpeg"
    "gif"  = "image/gif"
    "svg"  = "image/svg+xml"
    "ico"  = "image/x-icon"
  }

  # Azure primary endpoint
  azure_website_endpoint = "${var.azure_storage_website.storage_account_name}.z13.web.core.windows.net"
}
