variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "nginx-app"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

# Cloud Provider Toggles
variable "enable_azure" {
  description = "Enable Azure deployment"
  type        = bool
  default     = true
}

variable "enable_aws" {
  description = "Enable AWS deployment"
  type        = bool
  default     = false
}

# Azure Configuration
variable "azure_location" {
  description = "Azure region for deployment"
  type        = string
  default     = "eastus"
}

# Networking Configuration
variable "vnet_cidr" {
  description = "CIDR block for virtual network"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR block for public subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "private_subnet_cidr" {
  description = "CIDR block for private subnet"
  type        = string
  default     = "10.0.2.0/24"
}

variable "allowed_ssh_cidr" {
  description = "CIDR block allowed for SSH access"
  type        = string
  default     = "*"
}

# Compute Configuration
variable "vm_count" {
  description = "Number of VMs to deploy"
  type        = number
  default     = 1
}

variable "vm_size" {
  description = "Azure VM size"
  type        = string
  default     = "Standard_D2s_v3"
}

variable "admin_username" {
  description = "Admin username for VMs"
  type        = string
  default     = "azureuser"
}

variable "ssh_public_key" {
  description = "SSH public key for VM access"
  type        = string
}

# Application Gateway Configuration
variable "appgw_sku_name" {
  description = "Application Gateway SKU name"
  type        = string
  default     = "Standard_v2"
}

variable "appgw_sku_tier" {
  description = "Application Gateway SKU tier"
  type        = string
  default     = "Standard_v2"
}

variable "appgw_capacity" {
  description = "Application Gateway capacity"
  type        = number
  default     = 2
}
