# ==============================================================================
# MULTICLOUD WEATHER APP - PROVIDERS
# ==============================================================================
# Provider configurations for AWS and Azure
# Author: Vitor  
# Created: 2026-07-31
# ==============================================================================

terraform {
  required_version = ">= 1.0"

  # TODO: Configure remote backend (S3 + DynamoDB)
  # backend "s3" {
  #   bucket         = "your-terraform-state-bucket"
  #   key            = "multicloud-weather-app/terraform.tfstate"
  #   region         = "us-east-1"
  #   dynamodb_table = "terraform-state-locks"
  #   encrypt        = true
  # }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    dns = {
      source  = "hashicorp/dns"
      version = "~> 3.4"
    }
  }
}

# AWS Provider Configuration
provider "aws" {
  access_key = var.aws_credentials.access_key
  secret_key = var.aws_credentials.secret_key
  region     = var.aws_region

  default_tags {
    tags = local.common_tags
  }
}

# Azure Provider Configuration
provider "azurerm" {
  features {}

  client_id       = var.azure_credentials.client_id
  client_secret   = var.azure_credentials.client_secret
  subscription_id = var.azure_credentials.subscription_id
  tenant_id       = var.azure_credentials.tenant_id
}