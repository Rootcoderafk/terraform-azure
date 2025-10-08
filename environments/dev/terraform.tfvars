# Dev Environment Configuration

project_name = "nginx-app"
environment  = "dev"

# Cloud Provider Settings
enable_azure = true
enable_aws   = false

# Azure Settings
azure_location = "eastus"

# Network Configuration
vnet_cidr           = "10.0.0.0/16"
public_subnet_cidr  = "10.0.1.0/24"
private_subnet_cidr = "10.0.2.0/24"
allowed_ssh_cidr    = "*"  # Change to your IP in production

# Compute Configuration
vm_count       = 1
vm_size        = "Standard_D2s_v3"
admin_username = "azureuser"

# SSH public key - REPLACE WITH YOUR OWN
ssh_public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCs03OqWixRNk+Yioo5NwYY1sXADDJbxs+ngl5ZDcaAtmfI5BdQNJCOGqlE0O6nB+iHk5jedmoaih6kMDQu0R/1b8dufdMAUfwvi/pMlKVzCPu921YUBkPeXjlY1Nrdza0juTRq3Qf72OdO3jxcrdGk285nfRnc1QnRIIf4r/k1QyEhAmyFvJ1fJsmGyBoYSeLQXy/jnuXr0r+FuYRSxqYVPZj4CMZT+bO2Sr2g49/tIFT+YnhEiyyqnwRTEzjpUJr++FJgfGMRgD+6T4AmInSAY/S8fAu/BjxwAtCIiB6IzscQ7lQgwumewRm+m4uAhPI+M9scRZfF92xF6zuRqmkYfWTiNw7e2SGeBICDAQo4TV8ZmDszwREayOFOGLxkh6dtmMNrwJj2eq8ZIHu4bja2/1Zrjel91nhuFkzMkbrhFl5JzHn0B59jHSzKHvPWkm4AyD9kC46SKLRTkEvOBUJnPI21gq06offmlRRSs1LUdBTNfDDXKcQgs/z03YJhhPZXdVgKZGjgZeTGDUCOFrTufDvP2AyfKwItj45KIYxEY3tY4fW73fP7sIeSUjFDKxZFy6XD7b0anfKe9vXAl33Rwmkfingr8QVvY8v4PU6z5ruMWY6f/g9TQqshkC8gnvt4O+k4vzrA/VUNwUdO1Bkq4exbB/t6YWLI/H4BHQTTpw== aditya@aditya"

# Application Gateway Configuration
appgw_sku_name = "Standard_v2"
appgw_sku_tier = "Standard_v2"
appgw_capacity = 2
