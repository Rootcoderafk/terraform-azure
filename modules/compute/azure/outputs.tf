output "vm_ids" {
  description = "IDs of the virtual machines"
  value       = azurerm_linux_virtual_machine.main[*].id
}

output "vm_names" {
  description = "Names of the virtual machines"
  value       = azurerm_linux_virtual_machine.main[*].name
}

output "private_ips" {
  description = "Private IP addresses of the VMs"
  value       = azurerm_network_interface.main[*].private_ip_address
}

output "network_interface_ids" {
  description = "Network interface IDs"
  value       = azurerm_network_interface.main[*].id
}
