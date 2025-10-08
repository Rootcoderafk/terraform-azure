variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "eastus"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID for Application Gateway"
  type        = string
}

variable "backend_ips" {
  description = "List of backend VM private IP addresses"
  type        = list(string)
}

variable "sku_name" {
  description = "SKU name for Application Gateway"
  type        = string
  default     = "Standard_v2"
}

variable "sku_tier" {
  description = "SKU tier for Application Gateway"
  type        = string
  default     = "Standard_v2"
}

variable "capacity" {
  description = "Capacity (instance count) for Application Gateway"
  type        = number
  default     = 2
}

variable "ssl_certificate_password" {
  description = "Password for SSL certificate"
  type        = string
  sensitive   = true
  default     = "P@ssw0rd123"
}
