# Terraform Backend Configuration
# Stores state in Azure Storage Account

terraform {
  backend "azurerm" {
    resource_group_name  = "terraform-state-rg"
    storage_account_name = "tfstate9851838"  # Must be globally unique
    container_name       = "tfstate"
    key                  = "dev.terraform.tfstate"
  }
}

# To set up the backend, run these commands first:
#
# az group create --name terraform-state-rg --location eastus
#
# az storage account create \
#   --name tfstate9851838 \
#   --resource-group terraform-state-rg \
#   --location eastus \
#   --sku Standard_LRS
#
# az storage container create \
#   --name tfstate \
#   --account-name tfstate9851838
