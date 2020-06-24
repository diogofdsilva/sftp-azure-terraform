# Configure the Microsoft Azure Provider
provider "azurerm" {
    # The "feature" block is required for AzureRM provider 2.x.
    # If you're using version 1.x, the "features" block is not allowed.
    version = "~>2.0"
    features {}

    #subscription_id = var.AZURE_SUBSCRIPTION_ID
    #client_id       = var.AZURE_CLIENT_ID
    #client_secret   = var.AZURE_CLIENT_SECRET
    #tenant_id       = var.AZURE_TENANT_ID
}

provider "random" {
  version = "=2.2.1"
}