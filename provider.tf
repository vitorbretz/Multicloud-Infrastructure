provider "aws" {
  access_key = var.aws_credentials.access_key
  secret_key = var.aws_credentials.secret_key
  region     = var.aws_region

  default_tags {
    tags = local.common_tags
  }
}

provider "azurerm" {
  features {}

  client_id       = var.azure_credentials.client_id
  client_secret   = var.azure_credentials.client_secret
  subscription_id = var.azure_credentials.subscription_id
  tenant_id       = var.azure_credentials.tenant_id
}
