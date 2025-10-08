output "resource_group_name" {
  description = "Name of the resource group"
  value       = var.enable_azure ? azurerm_resource_group.main[0].name : null
}

output "vnet_id" {
  description = "ID of the virtual network"
  value       = var.enable_azure ? module.networking[0].vnet_id : null
}

output "vm_private_ips" {
  description = "Private IP addresses of the VMs"
  value       = var.enable_azure ? module.compute[0].private_ips : null
}

output "app_gateway_dns" {
  description = "DNS name of the Application Gateway"
  value       = var.enable_azure ? module.loadbalancer[0].app_gateway_dns : null
}

output "app_gateway_public_ip" {
  description = "Public IP of the Application Gateway"
  value       = var.enable_azure ? module.loadbalancer[0].public_ip : null
}

output "access_url" {
  description = "URL to access the application"
  value       = var.enable_azure ? "https://${module.loadbalancer[0].app_gateway_dns}" : null
}
