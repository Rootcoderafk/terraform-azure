# Azure Compute Module
# Creates Azure VMs with Docker and NGINX

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

# Network Interface for each VM
resource "azurerm_network_interface" "main" {
  count               = var.vm_count
  name                = "${var.environment}-vm-nic-${count.index + 1}"
  location            = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Dynamic"
  }

  tags = {
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# Virtual Machine
resource "azurerm_linux_virtual_machine" "main" {
  count               = var.vm_count
  name                = "${var.environment}-vm-${count.index + 1}"
  location            = var.location
  resource_group_name = var.resource_group_name
  size                = var.vm_size
  admin_username      = var.admin_username

  network_interface_ids = [
    azurerm_network_interface.main[count.index].id
  ]

  admin_ssh_key {
    username   = var.admin_username
    public_key = var.ssh_public_key
  }

  os_disk {
    name                 = "${var.environment}-vm-osdisk-${count.index + 1}"
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  # Cloud-init configuration for Docker and NGINX
  custom_data = base64encode(templatefile("${path.module}/cloud-init.yaml", {
    environment = var.environment
  }))

  tags = {
    Environment = var.environment
    ManagedBy   = "Terraform"
    Role        = "WebServer"
  }
}
