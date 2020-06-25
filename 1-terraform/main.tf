terraform {
  backend "azurerm" {
    # resource_group_name  = "${var.AZURE_STATE_RESOURCE_GROUP_NAME}"
    # storage_account_name = "${var.AZURE_STATE_STORAGE_NAME}"
    container_name       = "tfstate"
    key                  = "prod.terraform.tfstate"
  }
}

resource "azurerm_resource_group" "sftpresourcegroup" {
    name     = "${var.project_name}_sftp_RG"
    location = var.AZURE_LOCATION

    tags = {
        environment = "sftp-azure-terraform"
    }
}

resource "azurerm_virtual_network" "sftpterraformnetwork" {
    name                = "${var.project_name}_sftp_vnet"
    address_space       = ["10.0.0.0/16"]
    location            = var.AZURE_LOCATION
    resource_group_name = azurerm_resource_group.sftpresourcegroup.name

    tags = {
        environment = "sftp-azure-terraform"
    }
}

resource "azurerm_subnet" "sftpterraformsubnet" {
    name                 = "${var.project_name}_sftp_subnet"
    resource_group_name  = azurerm_resource_group.sftpresourcegroup.name
    virtual_network_name = azurerm_virtual_network.sftpterraformnetwork.name
    address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_public_ip" "sftpterraformpublicip" {
    name                         = "${var.project_name}_sftp_PIP"
    location                     = var.AZURE_LOCATION
    resource_group_name          = azurerm_resource_group.sftpresourcegroup.name
    allocation_method            = "Dynamic"
    domain_name_label            = "${var.project_name}sftp"

    tags = {
        environment = "sftp-azure-terraform"
    }
}

resource "azurerm_network_security_group" "sftpterraformnsg" {
    name                = "${var.project_name}_sftp_NSG"
    location            = var.AZURE_LOCATION
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

resource "azurerm_network_interface" "sftpterraformnic" {
    name                      = "${var.project_name}_sftp_NIC"
    location                  = var.AZURE_LOCATION
    resource_group_name       = azurerm_resource_group.sftpresourcegroup.name

    ip_configuration {
        name                          = "${var.project_name}_sftp_NicConfiguration"
        subnet_id                     = azurerm_subnet.sftpterraformsubnet.id
        private_ip_address_allocation = "Dynamic"
        public_ip_address_id          = azurerm_public_ip.sftpterraformpublicip.id
    }

    tags = {
        environment = "sftp-azure-terraform"
    }
}

resource "azurerm_network_interface_security_group_association" "example" {
    network_interface_id      = azurerm_network_interface.sftpterraformnic.id
    network_security_group_id = azurerm_network_security_group.sftpterraformnsg.id
}

resource "random_id" "randomId" {
    keepers = {
        # Generate a new ID only when a new resource group is defined
        resource_group = azurerm_resource_group.sftpresourcegroup.name
    }

    byte_length = 8
}

resource "azurerm_storage_account" "sftpstorageaccount" {
    name                        = "diag${random_id.randomId.hex}"
    resource_group_name         = azurerm_resource_group.sftpresourcegroup.name
    location                    = var.AZURE_LOCATION
    account_tier                = "Standard"
    account_replication_type    = "LRS"

    tags = {
        environment = "sftp-azure-terraform"
    }
}

resource "azurerm_linux_virtual_machine" "sftpterraformvm" {
    name                  = "${var.project_name}-sftp-VM"
    location              = var.AZURE_LOCATION
    resource_group_name   = azurerm_resource_group.sftpresourcegroup.name
    network_interface_ids = [azurerm_network_interface.sftpterraformnic.id]
    size                  = "Standard_DS1_v2"

    os_disk {
        name              = "${var.project_name}_sftp_OsDisk"
        caching           = "ReadWrite"
        storage_account_type = "Premium_LRS"
    }

    source_image_reference {
        publisher = "Canonical"
        offer     = "UbuntuServer"
        sku       = "16.04.0-LTS"
        version   = "latest"
    }

    computer_name  = "${var.project_name}-sftp-vm"
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

resource "azurerm_storage_account" "sftpstorageacct" {
    name                     = "${var.project_name}sharesftp"
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
