# Main Terraform Configuration for Dev Environment
# Orchestrates all modules for Azure deployment

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

# Resource Group
resource "azurerm_resource_group" "main" {
  count    = var.enable_azure ? 1 : 0
  name     = "${var.project_name}-${var.environment}-rg"
  location = var.azure_location

  tags = {
    Environment = var.environment
    ManagedBy   = "Terraform"
    Project     = var.project_name
  }
}

# Networking Module
module "networking" {
  source = "../../modules/networking/azure"
  count  = var.enable_azure ? 1 : 0

  resource_group_name  = azurerm_resource_group.main[0].name
  location            = var.azure_location
  environment         = var.environment
  vnet_cidr           = var.vnet_cidr
  public_subnet_cidr  = var.public_subnet_cidr
  private_subnet_cidr = var.private_subnet_cidr
  allowed_ssh_cidr    = var.allowed_ssh_cidr
}

# Compute Module
module "compute" {
  source = "../../modules/compute/azure"
  count  = var.enable_azure ? 1 : 0

  resource_group_name = azurerm_resource_group.main[0].name
  location           = var.azure_location
  environment        = var.environment
  subnet_id          = module.networking[0].private_subnet_id
  vm_count           = var.vm_count
  vm_size            = var.vm_size
  admin_username     = var.admin_username
  ssh_public_key     = var.ssh_public_key

  depends_on = [module.networking]
}

# Load Balancer Module
module "loadbalancer" {
  source = "../../modules/loadbalancer/azure"
  count  = var.enable_azure ? 1 : 0

  resource_group_name = azurerm_resource_group.main[0].name
  location           = var.azure_location
  environment        = var.environment
  subnet_id          = module.networking[0].public_subnet_id
  backend_ips        = module.compute[0].private_ips
  sku_name           = var.appgw_sku_name
  sku_tier           = var.appgw_sku_tier
  capacity           = var.appgw_capacity

  depends_on = [module.compute]
}
