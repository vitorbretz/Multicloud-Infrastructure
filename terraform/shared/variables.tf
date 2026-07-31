# Project Configuration
variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
  default     = "multicloud-weather-app"
  nullable    = false
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "prod"
  nullable    = false
}

variable "owner" {
  description = "Owner of the infrastructure"
  type        = string
  default     = "vitor"
  nullable    = false
}

# AWS Configuration
variable "aws_region" {
  description = "AWS region for resource deployment"
  type        = string
  default     = "us-east-1"
  nullable    = false
}

variable "aws_credentials" {
  description = "AWS authentication credentials"
  type = object({
    access_key = string
    secret_key = string
  })
  sensitive = true
}

variable "aws_s3_website" {
  description = "AWS S3 static website configuration"
  type = object({
    bucket_name = string
    website = object({
      index_document = string
      error_document = string
    })
    cache_control = object({
      html   = string
      css    = string
      js     = string
      assets = string
    })
    prevent_destroy = optional(bool, true)
  })
  default = {
    bucket_name = "multicloud-weather-app-vitor-2026"
    website = {
      index_document = "index.html"
      error_document = "error.html"
    }
    cache_control = {
      html   = "public, max-age=300"
      css    = "public, max-age=3600"
      js     = "public, max-age=3600"
      assets = "public, max-age=86400"
    }
    prevent_destroy = true
  }
}

# Azure Configuration
variable "azure_credentials" {
  description = "Azure authentication credentials"
  type = object({
    client_id       = string
    client_secret   = string
    subscription_id = string
    tenant_id       = string
  })
  sensitive = true
}

variable "azure_location" {
  description = "Azure region for resource deployment"
  type        = string
  default     = "East US"
  nullable    = false
}

variable "azure_storage_website" {
  description = "Azure Storage static website configuration"
  type = object({
    resource_group_name  = string
    storage_account_name = string
    account_tier         = optional(string, "Standard")
    replication_type     = optional(string, "LRS")
    website = object({
      index_document = string
      error_document = string
    })
    cors = optional(object({
      allowed_headers    = list(string)
      allowed_methods    = list(string)
      allowed_origins    = list(string)
      exposed_headers    = list(string)
      max_age_in_seconds = number
      }), {
      allowed_headers    = ["*"]
      allowed_methods    = ["GET", "HEAD", "OPTIONS"]
      allowed_origins    = ["*"]
      exposed_headers    = ["*"]
      max_age_in_seconds = 3600
    })
    cache_control = object({
      html   = string
      css    = string
      js     = string
      assets = string
    })
  })
  default = {
    resource_group_name  = "rg-static-website"
    storage_account_name = "myaccounttostorageweb"
    account_tier         = "Standard"
    replication_type     = "LRS"
    website = {
      index_document = "index.html"
      error_document = "error.html"
    }
    cors = {
      allowed_headers    = ["*"]
      allowed_methods    = ["GET", "HEAD", "OPTIONS"]
      allowed_origins    = ["*"]
      exposed_headers    = ["*"]
      max_age_in_seconds = 3600
    }
    cache_control = {
      html   = "public, max-age=300"
      css    = "public, max-age=3600"
      js     = "public, max-age=3600"
      assets = "public, max-age=86400"
    }
  }
}

# Website Files Configuration
variable "website_source_path" {
  description = "Path to website source files"
  type        = string
  default     = "website"
  nullable    = false
}

# DNS Configuration
variable "dns_config" {
  description = "Route53 DNS configuration with failover"
  type = object({
    domain_name        = string
    cloudfront_domain  = string
    cloudfront_zone_id = string
    
    apex_failover = object({
      enabled         = bool
      approach        = string  # "redirect", "native", "cloudflare"
      redirect_target = optional(string, "www")  # for redirect approach
    })
    
    health_checks = object({
      request_interval  = optional(number, 30)
      failure_threshold = optional(number, 3)
    })
  })
  default = {
    domain_name        = "cloud.flog.br"
    cloudfront_domain  = "d32ri76eiboi37.cloudfront.net"
    cloudfront_zone_id = "Z2FDTNDATAQYW2"
    
    apex_failover = {
      enabled         = true
      approach        = "redirect"
      redirect_target = "www"
    }
    
    health_checks = {
      request_interval  = 30
      failure_threshold = 3
    }
  }
}
