output "sftp_storage_account_primary_access_key" {
    value = azurerm_storage_account.sftpstorageacct.primary_access_key
}

output "domain_name_label" {
  value = azurerm_public_ip.sftpterraformpublicip.fqdn
}

output "virtual_machine_admin_user" {
  value = azurerm_linux_virtual_machine.sftpterraformvm.admin_username
}

output "virtual_machine_admin_pwd" {
  value = azurerm_linux_virtual_machine.sftpterraformvm.admin_password
}