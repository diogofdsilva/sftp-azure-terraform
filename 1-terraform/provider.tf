# Configure the Microsoft Azure Provider
provider "azurerm" {
    version = "2.15.0"
    features {}

    #subscription_id = var.AZURE_SUBSCRIPTION_ID
    #client_id       = var.AZURE_CLIENT_ID
    #client_secret   = var.AZURE_CLIENT_SECRET
    #tenant_id       = var.AZURE_TENANT_ID
}

provider "random" {
  version = "=2.2.1"
}