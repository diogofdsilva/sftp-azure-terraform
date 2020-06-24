output "sftp_storage_account_primary_access_key" {
    value = azurerm_storage_account.sftpstorageacct.primary_access_key
}

output "domain_name_label" {
  value = azurerm_public_ip.sftpterraformpublicip.fqdn
}

output "public_ip_address" {
  value = azurerm_public_ip.sftpterraformpublicip.ip_address
}