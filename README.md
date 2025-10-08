# 🚀 Multi-Cloud Terraform Infrastructure

Scalable, modular Terraform infrastructure supporting multiple environments and cloud providers (AWS & Azure).

## 📋 Table of Contents
- [Architecture Overview](#architecture-overview)
- [Prerequisites](#prerequisites)
- [Directory Structure](#directory-structure)
- [Quick Start](#quick-start)
- [Environment Setup](#environment-setup)
- [Deployment Instructions](#deployment-instructions)
- [CI/CD Pipelines](#cicd-pipelines)
- [Module Documentation](#module-documentation)
- [Troubleshooting](#troubleshooting)

---

## 🏗️ Architecture Overview

### Infrastructure Components

**Azure Deployment:**
- Virtual Network with public/private subnets
- NAT Gateway for outbound internet access from private subnet
- Ubuntu VM in private subnet (no public IP)
- Application Gateway with HTTPS listener
- Network Security Group (ports 22, 80, 443)
- Dockerized NGINX with self-signed SSL certificates

**AWS Configuration (Ready for deployment):**
- VPC with public/private subnets
- NAT Gateway for private subnet internet access
- EC2 instances in private subnet (no public IPs)
- Application Load Balancer with HTTPS
- Security Groups (ports 22, 80, 443)
- Same Dockerized NGINX setup

### Key Features
✅ Modular, reusable Terraform modules
✅ Multi-environment support (dev, staging, prod)
✅ Multi-cloud ready (AWS & Azure)
✅ Remote state management
✅ CI/CD pipelines (Jenkins & Azure DevOps)
✅ Dockerized NGINX with OpenSSL certificates
✅ Load balancer HTTPS termination

---

## 📦 Prerequisites

### Required Tools
```bash
# Terraform
terraform --version  # v1.5.0 or later

# Docker
docker --version

# Azure CLI
az --version

# AWS CLI (for future AWS deployment)
aws --version

# Git
git --version
```

### Cloud Provider Setup

#### Azure
```bash
# Login to Azure
az login

# Set subscription
az account set --subscription "YOUR_SUBSCRIPTION_ID"

# Create service principal for Terraform
az ad sp create-for-rbac \
  --name "terraform-sp" \
  --role="Contributor" \
  --scopes="/subscriptions/YOUR_SUBSCRIPTION_ID"

# Note the output:
# - appId (client_id)
# - password (client_secret)
# - tenant (tenant_id)
```

#### AWS (For future deployment)
```bash
# Configure AWS credentials
aws configure

# Or use environment variables
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"
export AWS_DEFAULT_REGION="us-east-1"
```

---

## 📁 Directory Structure

```
terraform-infrastructure/
├── modules/                    # Reusable Terraform modules
│   ├── networking/
│   │   ├── aws/               # AWS VPC, subnets, NAT
│   │   └── azure/             # Azure VNet, subnets, NAT
│   ├── compute/
│   │   ├── aws/               # EC2 instances
│   │   └── azure/             # Azure VMs
│   ├── loadbalancer/
│   │   ├── aws/               # Application Load Balancer
│   │   └── azure/             # Application Gateway
│   └── nginx-app/             # Docker + NGINX setup
├── environments/              # Environment-specific configs
│   ├── dev/
│   │   ├── main.tf
│   │   ├── terraform.tfvars
│   │   └── backend.tf
│   ├── staging/
│   └── prod/
├── docker/                    # Docker configuration
│   ├── Dockerfile
│   ├── nginx.conf
│   └── entrypoint.sh
├── scripts/                   # Helper scripts
│   ├── init-terraform.sh
│   ├── deploy.sh
│   └── destroy.sh
├── pipelines/                 # CI/CD configurations
│   ├── Jenkinsfile
│   └── azure-pipelines.yml
└── docs/                      # Additional documentation
```

---

## 🚀 Quick Start

### 1. Clone and Setup

```bash
# Navigate to the terraform directory
cd terraform-infrastructure

# Initialize Terraform modules
terraform init

# Validate configuration
terraform validate
```

### 2. Configure Environment Variables

Create a `.env` file (don't commit this):
```bash
# Azure
export ARM_CLIENT_ID="your-client-id"
export ARM_CLIENT_SECRET="your-client-secret"
export ARM_SUBSCRIPTION_ID="your-subscription-id"
export ARM_TENANT_ID="your-tenant-id"

# AWS (for future use)
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"
```

Load variables:
```bash
source .env
```

### 3. Deploy Azure Infrastructure (Dev Environment)

```bash
# Navigate to dev environment
cd environments/dev

# Initialize Terraform with backend
terraform init

# Plan the deployment
terraform plan -var-file="terraform.tfvars"

# Apply the configuration
terraform apply -var-file="terraform.tfvars" -auto-approve
```

---

## 🌍 Environment Setup

### Dev Environment
```bash
cd environments/dev
terraform workspace select dev || terraform workspace new dev
terraform apply -var-file="terraform.tfvars"
```

### Staging Environment
```bash
cd environments/staging
terraform workspace select staging || terraform workspace new staging
terraform apply -var-file="terraform.tfvars"
```

### Production Environment
```bash
cd environments/prod
terraform workspace select prod || terraform workspace new prod
terraform apply -var-file="terraform.tfvars"
```

---

## 📝 Deployment Instructions

### Azure Deployment (Current Focus)

#### Step 1: Setup Remote State Backend

```bash
# Create Azure Storage for Terraform state
az group create \
  --name terraform-state-rg \
  --location eastus

az storage account create \
  --name tfstateXXXXX \
  --resource-group terraform-state-rg \
  --location eastus \
  --sku Standard_LRS

az storage container create \
  --name tfstate \
  --account-name tfstateXXXXX
```

#### Step 2: Update Backend Configuration

Edit `environments/dev/backend.tf`:
```hcl
terraform {
  backend "azurerm" {
    resource_group_name  = "terraform-state-rg"
    storage_account_name = "tfstateXXXXX"
    container_name       = "tfstate"
    key                  = "dev.terraform.tfstate"
  }
}
```

#### Step 3: Deploy Infrastructure

```bash
# Using helper script
./scripts/deploy.sh dev azure

# Or manually
cd environments/dev
terraform init
terraform plan -var="enable_azure=true" -var="enable_aws=false"
terraform apply -var="enable_azure=true" -var="enable_aws=false"
```

#### Step 4: Verify Deployment

```bash
# Get Application Gateway DNS
terraform output app_gateway_dns

# Test NGINX
curl -k https://$(terraform output -raw app_gateway_dns)
```

### AWS Deployment (Future)

```bash
# Create S3 bucket for state
aws s3api create-bucket \
  --bucket terraform-state-bucket-XXXXX \
  --region us-east-1

# Enable versioning
aws s3api put-bucket-versioning \
  --bucket terraform-state-bucket-XXXXX \
  --versioning-configuration Status=Enabled

# Create DynamoDB table for state locking
aws dynamodb create-table \
  --table-name terraform-state-lock \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5

# Deploy
./scripts/deploy.sh prod aws
```

---

## 🔄 CI/CD Pipelines

### Jenkins Pipeline

**Setup:**
1. Install Jenkins plugins:
   - Terraform Plugin
   - Azure Credentials Plugin
   - Pipeline Plugin

2. Configure credentials in Jenkins:
   - Azure Service Principal
   - AWS Access Keys (for future)

3. Create Pipeline job pointing to `pipelines/Jenkinsfile`

**Trigger Deployment:**
```groovy
// Via Jenkins UI with parameters:
ENVIRONMENT: dev/staging/prod
CLOUD_PROVIDER: azure/aws
ACTION: plan/apply/destroy
```

### Azure DevOps Pipeline

**Setup:**
1. Create Azure DevOps project
2. Connect to Git repository
3. Create service connections:
   - Azure Resource Manager
   - AWS (for future)

4. Create pipeline from `pipelines/azure-pipelines.yml`

**Trigger Deployment:**
```bash
# Via Azure DevOps UI or CLI
az pipelines run \
  --name terraform-deploy \
  --variables environment=dev cloud_provider=azure
```

---

## 📚 Module Documentation

### Networking Module (Azure)

**Purpose:** Creates virtual network infrastructure with public/private subnets and NAT Gateway.

**Inputs:**
- `resource_group_name`: Resource group name
- `location`: Azure region
- `environment`: Environment name (dev/staging/prod)
- `vnet_cidr`: Virtual network CIDR block
- `public_subnet_cidr`: Public subnet CIDR
- `private_subnet_cidr`: Private subnet CIDR

**Outputs:**
- `vnet_id`: Virtual Network ID
- `public_subnet_id`: Public subnet ID
- `private_subnet_id`: Private subnet ID
- `nat_gateway_id`: NAT Gateway ID

**Usage:**
```hcl
module "networking" {
  source = "../../modules/networking/azure"
  
  resource_group_name  = "my-rg"
  location            = "eastus"
  environment         = "dev"
  vnet_cidr           = "10.0.0.0/16"
  public_subnet_cidr  = "10.0.1.0/24"
  private_subnet_cidr = "10.0.2.0/24"
}
```

### Compute Module (Azure)

**Purpose:** Deploys Azure VMs with Docker and NGINX.

**Inputs:**
- `resource_group_name`: Resource group name
- `location`: Azure region
- `environment`: Environment name
- `subnet_id`: Subnet for VM deployment
- `vm_count`: Number of VMs to deploy
- `vm_size`: Azure VM SKU
- `admin_username`: VM admin username
- `ssh_public_key`: SSH public key

**Outputs:**
- `vm_ids`: List of VM IDs
- `private_ips`: List of private IP addresses
- `vm_names`: List of VM names

### Load Balancer Module (Azure)

**Purpose:** Creates Application Gateway with HTTPS listener.

**Inputs:**
- `resource_group_name`: Resource group name
- `location`: Azure region
- `environment`: Environment name
- `subnet_id`: Subnet for Application Gateway
- `backend_ips`: List of backend VM IPs
- `ssl_certificate_path`: Path to SSL certificate

**Outputs:**
- `app_gateway_dns`: Application Gateway public DNS
- `app_gateway_id`: Application Gateway ID
- `public_ip`: Public IP address

---

## 🔐 Security Best Practices

### Network Security
- ✅ VMs deployed in private subnets (no public IPs)
- ✅ NAT Gateway for controlled outbound access
- ✅ Network Security Groups with minimal required ports
- ✅ Application Gateway as single entry point

### Access Control
- ✅ SSH key-based authentication (no passwords)
- ✅ Bastion host for secure VM access
- ✅ HTTPS-only communication
- ✅ Terraform state stored in encrypted backend

### SSL/TLS
- ✅ Self-signed certificates for development
- ⚠️ Replace with CA-signed certificates for production
- ✅ HTTPS redirection configured
- ✅ TLS 1.2+ enforced

---

## 🐳 Docker NGINX Configuration

### Building the Image

```bash
cd docker
docker build -t nginx-ssl:latest .
```

### Testing Locally

```bash
# Run container
docker run -d -p 80:80 -p 443:443 nginx-ssl:latest

# Test HTTPS
curl -k https://localhost

# View logs
docker logs <container-id>
```

### SSL Certificate Generation

Self-signed certificates are auto-generated in the container:
```bash
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout /etc/nginx/certs/key.pem \
  -out /etc/nginx/certs/cert.pem \
  -subj "/C=US/ST=State/L=City/O=Org/CN=localhost"
```

---

## 🔧 Troubleshooting

### Common Issues

#### Issue: Terraform init fails
```bash
# Solution: Clear cache and re-initialize
rm -rf .terraform
terraform init -upgrade
```

#### Issue: Azure authentication fails
```bash
# Solution: Re-login and verify subscription
az login
az account show
az account set --subscription "YOUR_SUBSCRIPTION_ID"
```

#### Issue: Cannot access Application Gateway
```bash
# Check NSG rules
az network nsg rule list \
  --resource-group <rg-name> \
  --nsg-name <nsg-name> \
  --output table

# Check Application Gateway backend health
az network application-gateway show-backend-health \
  --resource-group <rg-name> \
  --name <app-gateway-name>
```

#### Issue: Docker container not starting
```bash
# Check VM logs
ssh -i <key-path> azureuser@<vm-ip>
sudo docker logs <container-id>
sudo systemctl status docker
```

### Debugging Commands

```bash
# Terraform debugging
export TF_LOG=DEBUG
terraform plan

# Azure debugging
az rest --method get --url <resource-url> --debug

# Test network connectivity
curl -v -k https://<app-gateway-dns>
```

---

## 📊 Outputs After Deployment

After successful deployment, you'll get:

```bash
Outputs:

app_gateway_dns = "myapp-dev-appgw-XXXXX.eastus.cloudapp.azure.com"
vm_private_ips = [
  "10.0.2.4",
]
resource_group_name = "myapp-dev-rg"
vnet_id = "/subscriptions/.../virtualNetworks/myapp-dev-vnet"
```

**Access your application:**
```bash
# HTTPS (recommended)
https://<app_gateway_dns>

# Note: Browser will show security warning due to self-signed certificate
```

---

## 🧹 Cleanup

### Destroy Infrastructure

```bash
# Using helper script
./scripts/destroy.sh dev azure

# Or manually
cd environments/dev
terraform destroy -var-file="terraform.tfvars" -auto-approve
```

### Remove State Backend

```bash
# Azure
az storage account delete \
  --name tfstateXXXXX \
  --resource-group terraform-state-rg

az group delete --name terraform-state-rg

# AWS
aws s3 rb s3://terraform-state-bucket-XXXXX --force
aws dynamodb delete-table --table-name terraform-state-lock
```

---

## 📈 Scaling

### Horizontal Scaling (More VMs)

Edit `terraform.tfvars`:
```hcl
vm_count = 3  # Increase from 1 to 3
```

Apply changes:
```bash
terraform apply -var-file="terraform.tfvars"
```

### Vertical Scaling (Larger VMs)

Edit `terraform.tfvars`:
```hcl
vm_size = "Standard_D4s_v3"  # Upgrade from D2s_v3
```

---

## 🌐 Multi-Region Deployment

Deploy to multiple regions:

```bash
# East US deployment
cd environments/prod-eastus
terraform apply

# West Europe deployment  
cd environments/prod-westeurope
terraform apply
```

Configure Route 53 / Traffic Manager for global routing.

---

## 📞 Support

For issues or questions:
1. Check [Troubleshooting](#troubleshooting) section
2. Review Terraform/Azure documentation
3. Open an issue in the repository

---

## 📄 License

This infrastructure code is provided as-is for educational and production use.

---

**Last Updated:** 2025-10-07
**Version:** 1.0.0
