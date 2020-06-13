#{
#  "appId": "761e7965-77e9-42e5-a2ad-c8f254330262",
#  "displayName": "azure-cli-2020-04-02-18-23-23",
#  "name": "http://azure-cli-2020-04-02-18-23-23",
#  "password": "fb97fc88-8d0d-46ae-a41f-24b27a9fcbd5",
#  "tenant": "53d946b1-a3bd-45c9-a653-3afb6557e5c9"
#}

variable "azure_subscription_id" {
  type = string
}

variable "azure_client_id" {
  type = string
}

variable "azure_client_secret" {
  type = string
}

variable "azure_tenant_id" {
  type = string
}

variable "azure_location" {
  type = string
}

locals {
    project_name = "diogofdsilva"
}

# Configure the Microsoft Azure Provider
provider "azurerm" {
    # The "feature" block is required for AzureRM provider 2.x.
    # If you're using version 1.x, the "features" block is not allowed.
    version = "~>2.0"
    features {}

    subscription_id = var.azure_subscription_id
    client_id       = var.azure_client_id
    client_secret   = var.azure_client_secret
    tenant_id       = var.azure_tenant_id
}

# Create a resource group if it doesn't exist
resource "azurerm_resource_group" "sftpresourcegroup" {
    name     = "${local.project_name}_sftp_RG"
    location = var.azure_location

    tags = {
        environment = "sftp-azure-terraform"
    }
}

# Create virtual network
resource "azurerm_virtual_network" "sftpterraformnetwork" {
    name                = "${local.project_name}_sftp_vnet"
    address_space       = ["10.0.0.0/16"]
    location            = var.azure_location
    resource_group_name = azurerm_resource_group.sftpresourcegroup.name

    tags = {
        environment = "sftp-azure-terraform"
    }
}

# Create subnet
resource "azurerm_subnet" "sftpterraformsubnet" {
    name                 = "${local.project_name}_sftp_subnet"
    resource_group_name  = azurerm_resource_group.sftpresourcegroup.name
    virtual_network_name = azurerm_virtual_network.sftpterraformnetwork.name
    address_prefixes     = ["10.0.1.0/24"]
}

# Create public IPs
resource "azurerm_public_ip" "sftpterraformpublicip" {
    name                         = "${local.project_name}_sftp_PIP"
    location                     = var.azure_location
    resource_group_name          = azurerm_resource_group.sftpresourcegroup.name
    allocation_method            = "Dynamic"
    domain_name_label            = "${local.project_name}sftp"

    tags = {
        environment = "sftp-azure-terraform"
    }
}



# Create Network Security Group and rule
resource "azurerm_network_security_group" "sftpterraformnsg" {
    name                = "${local.project_name}_sftp_NSG"
    location            = var.azure_location
    resource_group_name = azurerm_resource_group.sftpresourcegroup.name

    security_rule {
        name                       = "SSH"
        priority                   = 1001
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "22"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }

    tags = {
        environment = "sftp-azure-terraform"
    }
}

# Create network interface
resource "azurerm_network_interface" "sftpterraformnic" {
    name                      = "${local.project_name}_sftp_NIC"
    location                  = var.azure_location
    resource_group_name       = azurerm_resource_group.sftpresourcegroup.name

    ip_configuration {
        name                          = "${local.project_name}_sftp_NicConfiguration"
        subnet_id                     = azurerm_subnet.sftpterraformsubnet.id
        private_ip_address_allocation = "Dynamic"
        public_ip_address_id          = azurerm_public_ip.sftpterraformpublicip.id
    }

    tags = {
        environment = "sftp-azure-terraform"
    }
}

# Connect the security group to the network interface
resource "azurerm_network_interface_security_group_association" "example" {
    network_interface_id      = azurerm_network_interface.sftpterraformnic.id
    network_security_group_id = azurerm_network_security_group.sftpterraformnsg.id
}

# Generate random text for a unique storage account name
resource "random_id" "randomId" {
    keepers = {
        # Generate a new ID only when a new resource group is defined
        resource_group = azurerm_resource_group.sftpresourcegroup.name
    }

    byte_length = 8
}

# Create storage account for boot diagnostics
resource "azurerm_storage_account" "sftpstorageaccount" {
    name                        = "diag${random_id.randomId.hex}"
    resource_group_name         = azurerm_resource_group.sftpresourcegroup.name
    location                    = var.azure_location
    account_tier                = "Standard"
    account_replication_type    = "LRS"

    tags = {
        environment = "sftp-azure-terraform"
    }
}

# Create virtual machine
resource "azurerm_linux_virtual_machine" "sftpterraformvm" {
    name                  = "${local.project_name}-sftp-VM"
    location              = var.azure_location
    resource_group_name   = azurerm_resource_group.sftpresourcegroup.name
    network_interface_ids = [azurerm_network_interface.sftpterraformnic.id]
    size                  = "Standard_DS1_v2"

    os_disk {
        name              = "${local.project_name}_sftp_OsDisk"
        caching           = "ReadWrite"
        storage_account_type = "Premium_LRS"
    }

    source_image_reference {
        publisher = "Canonical"
        offer     = "UbuntuServer"
        sku       = "16.04.0-LTS"
        version   = "latest"
    }

    computer_name  = "${local.project_name}-sftp-vm"
    admin_username = "azureuser"
    admin_password = "P2ssw0rd2018"
    disable_password_authentication = false


    boot_diagnostics {
        storage_account_uri = azurerm_storage_account.sftpstorageaccount.primary_blob_endpoint
    }

    tags = {
        environment = "sftp-azure-terraform"
    }
}

# Create storage share

resource "azurerm_storage_account" "sftpstorageacct" {
    name                     = "${local.project_name}sharesftp"
    resource_group_name      = azurerm_resource_group.sftpresourcegroup.name
    location                 = azurerm_resource_group.sftpresourcegroup.location
    account_tier             = "Standard"
    account_replication_type = "LRS"

    tags = {
        environment = "sftp-azure-terraform"
    }
}

resource "azurerm_storage_share" "sftpstorageacctshare" {
    name                 = "sharename"
    storage_account_name = azurerm_storage_account.sftpstorageacct.name
    quota                = 5
}

output "sftp_storage_account_primary_access_key" {
    value = azurerm_storage_account.sftpstorageacct.primary_access_key
}

output "domain_name_label" {
  value = azurerm_public_ip.sftpterraformpublicip.fqdn
}

output "public_ip_address" {
  value = azurerm_public_ip.sftpterraformpublicip.ip_address
}
