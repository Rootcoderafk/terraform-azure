# Multi-Cloud Terraform Infrastructure Project

Hey! Let me walk you through this infrastructure project I've built. This is a production-ready, scalable Terraform setup that I designed to work across multiple cloud providers. Right now, it's fully deployed on Azure, with AWS configurations ready to go whenever needed.

## What This Project Actually Does

I built this infrastructure to solve a real problem: deploying secure, scalable web applications across cloud providers without repeating myself. The core idea is simple - I have NGINX containers running behind load balancers, but the implementation is anything but basic.

### The Architecture I Chose (And Why)

When I started this project, security was my top priority. That's why I went with a private subnet architecture. Here's what I mean:

**On Azure (Currently Running):**
I set up a Virtual Network with two subnets. The first is public - that's where my Application Gateway lives. The second is private, and that's home to my Ubuntu VMs. These VMs have no public IPs whatsoever. They can reach the internet through a NAT Gateway I configured, but nothing on the internet can directly access them. That's the whole point.

Each VM runs Docker, which hosts my NGINX containers. Inside those containers, I generate self-signed SSL certificates using OpenSSL (more on that later). The Application Gateway handles all incoming HTTPS traffic and forwards it to my VMs on port 443.

I also set up Network Security Groups that only allow ports 22 (SSH), 80 (HTTP redirects), and 443 (HTTPS). Everything else is blocked by default.

**For AWS (Ready But Not Deployed Yet):**
I've configured the same architecture pattern for AWS. It uses a VPC with public and private subnets, a NAT Gateway for outbound traffic, EC2 instances in the private subnet, and an Application Load Balancer handling HTTPS. The security groups mirror what I did on Azure. It's all ready to deploy - I just haven't pulled the trigger yet because Azure is serving my needs perfectly for now.

### Why I Built It This Way

**Modularity Was Key:**
I hate repeating code. That's why I broke everything into reusable Terraform modules. Need another VM? Just increase the count. Want to deploy to a new environment? Copy the variables file and adjust a few settings. Want to add AWS alongside Azure? Toggle a flag. That's it.

**Security By Design:**
No public IPs on application servers. Everything goes through the load balancer. SSH access is key-based only - no passwords. HTTPS everywhere, even if it's self-signed certs for now (production would use proper CA certificates).

**Environment Separation:**
I built this to support dev, staging, and production environments from day one. Each environment has its own Terraform workspace, its own state file, and its own variable definitions. No accidents where someone tears down prod thinking it's dev.

**State Management:**
I'm using remote state backends (Azure Storage for Azure deployments, S3 + DynamoDB for AWS). State locking is enabled to prevent those nightmare scenarios where two people run terraform apply at the same time and corrupt the state.

### What Each Component Does

**The Networking Layer:**
This is where I define my virtual networks, subnets, and routing rules. The public subnet houses the NAT Gateway and Load Balancer. The private subnet is where my VMs live. I set up route tables so private subnet traffic destined for the internet goes through the NAT Gateway.

**The Compute Layer:**
This module creates my VMs. I'm using cloud-init to bootstrap each VM with Docker. The moment a VM spins up, it pulls my NGINX Docker image and starts the container. I use count to allow multiple VMs from the same config.

**The Load Balancer Layer:**
This is my traffic director. On Azure, I'm using Application Gateway with an HTTPS listener. It terminates SSL at the gateway, then forwards requests to backend VMs. Health probes ensure traffic only goes to healthy instances.

**The Docker Application:**
Inside my Docker containers, I have NGINX configured to serve HTTPS. An entrypoint script generates self-signed certificates on container startup. The nginx.conf file handles SSL configuration and redirects HTTP to HTTPS.

### The Files That Make It All Work

Let me break down the directory structure and explain what each file does:

## Project Structure Deep Dive

```
terraform-infrastructure/
├── modules/                    # My reusable Terraform modules
│   ├── networking/
│   │   └── azure/
│   │       ├── main.tf        # VNet, subnets, NAT Gateway definitions
│   │       ├── variables.tf   # Input parameters (CIDR blocks, location, etc.)
│   │       └── outputs.tf     # Exports VNet ID, subnet IDs for other modules
│   ├── compute/
│   │   └── azure/
│   │       ├── main.tf        # VM definitions, network interfaces
│   │       ├── variables.tf   # VM size, count, SSH keys, admin username
│   │       ├── outputs.tf     # VM IDs, private IPs
│   │       └── cloud-init.yaml # Bootstraps Docker on VM startup
│   └── loadbalancer/
│       └── azure/
│           ├── main.tf        # Application Gateway config
│           ├── variables.tf   # Backend IPs, SSL cert path
│           ├── outputs.tf     # Public DNS, gateway ID
│           └── generate-cert.sh # Creates self-signed cert for App Gateway
│
├── environments/              # Environment-specific configurations
│   ├── dev/
│   │   ├── main.tf           # Calls all modules with dev-specific params
│   │   ├── variables.tf      # Defines what inputs this env accepts
│   │   ├── terraform.tfvars  # Actual values (SSH key, VM size, etc.)
│   │   ├── outputs.tf        # What info to display after deployment
│   │   └── backend.tf        # Remote state config (Azure Storage)
│   ├── staging/              # Same structure, different values
│   └── prod/                 # Same structure, production values
│
├── docker/                   # Application container setup
│   ├── Dockerfile           # Builds NGINX image with SSL support
│   ├── nginx.conf           # NGINX config (SSL, redirects, server blocks)
│   ├── entrypoint.sh        # Generates SSL certs on container start
│   ├── index.html           # Simple HTML page to verify deployment
│   └── build-and-test.sh    # Local testing script
│
├── scripts/                 # Automation helpers
│   ├── init-terraform.sh   # Sets up remote state backend in Azure
│   ├── deploy.sh           # Wrapper for plan/apply/destroy
│   └── destroy.sh          # Clean teardown script
│
├── pipelines/              # CI/CD configurations
│   ├── Jenkinsfile        # Jenkins pipeline definition
│   └── azure-pipelines.yml # Azure DevOps YAML pipeline
│
└── README.md              # This file you're reading right now
```

### How These Files Work Together

**When I Deploy Dev Environment:**
1. I run `terraform init` in `environments/dev/` - Terraform reads `backend.tf` and connects to my Azure Storage backend
2. Terraform loads `main.tf`, which calls my three modules (networking, compute, loadbalancer)
3. Each module reads its variables from `terraform.tfvars`
4. The networking module creates the VNet first (because modules depend on it)
5. The compute module uses networking outputs (subnet IDs) to create VMs
6. The loadbalancer module uses compute outputs (private IPs) to configure backend pool
7. Cloud-init runs on each VM, installing Docker and pulling my NGINX image
8. Application Gateway starts routing HTTPS traffic to the VMs

**The Docker Workflow:**
1. `Dockerfile` defines my NGINX image with SSL support
2. When container starts, `entrypoint.sh` runs first
3. It generates self-signed certificates using OpenSSL
4. Then it starts NGINX with my custom `nginx.conf`
5. NGINX serves `index.html` over HTTPS on port 443

**The CI/CD Flow:**
1. I push code changes to Git
2. Jenkins or Azure DevOps detects the change
3. Pipeline runs `terraform plan` to preview changes
4. If approved, runs `terraform apply`
5. Pipeline outputs the Application Gateway DNS
6. I can access the app at `https://<app-gateway-dns>`

---

## What You Need Before Starting
I'm assuming you have these tools installed. If not, here's what you need:

**Terraform** (v1.5.0 or newer) - This is obvious. The whole project is Terraform.

**Docker** - You'll need this if you want to build and test the NGINX image locally before deploying.

**Azure CLI** - For authenticating with Azure and setting up the remote state backend.

**AWS CLI** - Only if you plan to deploy the AWS infrastructure. I haven't activated AWS yet, so it's optional for now.

**Git** - For version control. My CI/CD pipelines expect code in Git.

**An SSH Key Pair** - You'll need this for VM access. Generate one with `ssh-keygen` if you don't have one.

### Setting Up Azure (Required For Current Deployment)

Here's how I set up my Azure access:

First, I log into Azure and select my subscription:
```bash
az login
az account set --subscription "YOUR_SUBSCRIPTION_ID"
```

Then I create a service principal for Terraform. This gives Terraform the permissions it needs to create resources:
```bash
az ad sp create-for-rbac \
  --name "terraform-sp" \
  --role="Contributor" \
  --scopes="/subscriptions/YOUR_SUBSCRIPTION_ID"
```

The output gives me four values I need: `appId`, `password`, `tenant`, and my subscription ID. I export these as environment variables:
```bash
export ARM_CLIENT_ID="<appId>"
export ARM_CLIENT_SECRET="<password>"
export ARM_SUBSCRIPTION_ID="<your-subscription-id>"
export ARM_TENANT_ID="<tenant>"
```

### AWS Setup (When I'm Ready To Deploy There)
For AWS, it's simpler. I just configure credentials:
```bash
aws configure
```

Or use environment variables:
```bash
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"
export AWS_DEFAULT_REGION="us-east-1"
```

---

## Getting Started - The Quick Way

Let me show you how I deploy this infrastructure from scratch:

### Step 1: Set Up The Remote State Backend

Before doing anything else, I need a place to store Terraform's state file. I use Azure Storage for this:

```bash
cd terraform-infrastructure
./scripts/init-terraform.sh azure
```

This script creates an Azure Storage Account and container for my Terraform state. It's automated because I got tired of doing it manually.

### Step 2: Generate SSL Certificate For Application Gateway

The Application Gateway needs an SSL certificate. For dev, I use a self-signed one:
```bash
cd modules/loadbalancer/azure
./generate-cert.sh
```

This creates a PFX certificate file that Azure Application Gateway can use.

### Step 3: Configure Your SSH Key

I need to tell Terraform my SSH public key so I can access the VMs. Edit `environments/dev/terraform.tfvars`:

```hcl
ssh_public_key = "ssh-rsa AAAAB3... your-public-key-here"
```

Replace that with your actual public key (usually found in `~/.ssh/id_rsa.pub`).

### Step 4: Deploy The Infrastructure

Now for the fun part. I run the deploy script:

```bash
./scripts/deploy.sh dev azure apply
```

This does several things:
1. Navigates to `environments/dev/`
2. Runs `terraform init` to set up the backend
3. Runs `terraform apply` to create all resources

It takes about 10-15 minutes to complete. I watch as it creates:
- Resource group
- Virtual network and subnets
- NAT Gateway
- Network Security Group
- Virtual Machine
- Application Gateway
- All the networking glue that ties it together

### Step 5: Access The Application

When it's done, Terraform outputs the Application Gateway DNS. I copy that and visit:

```bash
https://<app-gateway-dns>
```

My browser complains about the self-signed certificate (expected), I click through the warning, and boom - I see my NGINX welcome page.

---

## Working With Multiple Environments

Here's how I manage dev, staging, and prod:

### Deploying Dev

```bash
cd environments/dev
terraform workspace select dev || terraform workspace new dev
terraform apply -var-file="terraform.tfvars"
```

### Deploying Staging

```bash
cd environments/staging
terraform workspace select staging || terraform workspace new staging
terraform apply -var-file="terraform.tfvars"
```

### Deploying Production

```bash
cd environments/prod
terraform workspace select prod || terraform workspace new prod
terraform apply -var-file="terraform.tfvars"
```

Each environment has its own:
- Workspace (isolated state)
- Variable file (different VM sizes, counts, etc.)
- Resource naming (prefixed with environment name)

---

## The Detailed Deployment Process

Let me walk through what actually happens when I deploy to Azure:

### Setting Up The State Backend

First time only, I need somewhere to store state:

```bash
az group create --name terraform-state-rg --location eastus

az storage account create \
  --name tfstateXXXXX \
  --resource-group terraform-state-rg \
  --location eastus \
  --sku Standard_LRS

az storage container create \
  --name tfstate \
  --account-name tfstateXXXXX
```

Replace `tfstateXXXXX` with a unique name (storage account names must be globally unique).

Then I update `environments/dev/backend.tf` with my storage account name:
```hcl
terraform {
  backend "azurerm" {
    resource_group_name  = "terraform-state-rg"
    storage_account_name = "tfstate12345"  # ← My unique name here
    container_name       = "tfstate"
    key                  = "dev.terraform.tfstate"
  }
}
```

### Deploying The Infrastructure

I have two options here. Use my helper script:

```bash
./scripts/deploy.sh dev azure apply
```

Or do it manually if I want more control:

```bash
cd environments/dev
terraform init
terraform plan
terraform apply
```

I prefer the script because it handles navigation and flags for me.

### Verifying Everything Works

After deployment, I grab the Application Gateway DNS:

```bash
cd environments/dev
terraform output app_gateway_dns
```

Then test it:

```bash
curl -k https://$(terraform output -raw app_gateway_dns)
```

The `-k` flag tells curl to ignore the self-signed certificate warning.

### When I'm Ready For AWS

The same process applies to AWS, just with different services:

```bash
# Create S3 bucket for state
aws s3api create-bucket \
  --bucket terraform-state-bucket-XXXXX \
  --region us-east-1

# Enable versioning (important!)
aws s3api put-bucket-versioning \
  --bucket terraform-state-bucket-XXXXX \
  --versioning-configuration Status=Enabled

# Create DynamoDB table for state locking
aws dynamodb create-table \
  --table-name terraform-state-lock \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5

# Then deploy
./scripts/deploy.sh dev aws apply
```

---

## How I Set Up CI/CD

I built two pipeline configurations - one for Jenkins and one for Azure DevOps. Pick whichever one you use.

### The Jenkins Pipeline

My Jenkinsfile defines three stages: Plan, Approve, and Apply.

**Here's how I set it up:**

1. Installed these Jenkins plugins:
   - Terraform Plugin (to run terraform commands)
   - Azure Credentials Plugin (for authentication)
   - Pipeline Plugin (for Jenkinsfile support)

2. Added credentials in Jenkins:
   - Created an Azure Service Principal credential
   - Added AWS access keys (for when I deploy AWS)

3. Created a new Pipeline job and pointed it to `pipelines/Jenkinsfile`

**To trigger a deployment:**
I run the job and it asks me for parameters:
- Environment: dev, staging, or prod
- Cloud Provider: azure or aws
- Action: plan, apply, or destroy

The pipeline then:
1. Checks out the code
2. Runs `terraform plan` and shows me what will change
3. Waits for my approval
4. Runs `terraform apply` if I approve

### The Azure DevOps Pipeline

My `azure-pipelines.yml` is set up similarly.

**Setup steps:**

1. Created an Azure DevOps project
2. Connected it to my Git repository
3. Set up service connections:
   - Azure Resource Manager connection (for my Azure subscription)
   - AWS connection (for future use)

4. Created a new pipeline from `pipelines/azure-pipelines.yml`

**To run a deployment:**
I can trigger it from the UI or use the CLI:
```bash
az pipelines run \
  --name terraform-deploy \
  --variables environment=dev cloud_provider=azure
```

The pipeline does the same thing as Jenkins - plan, wait for approval, apply.

---

## Understanding The Modules

Let me explain what each module does and how to use it.

### The Networking Module

This module creates the foundational network infrastructure. Without it, nothing else works.

**What it creates on Azure:**
- A Virtual Network (VNet) with the CIDR block I specify
- A public subnet (for the Application Gateway and NAT)
- A private subnet (where my VMs live)
- A NAT Gateway (so private VMs can reach the internet)
- Route tables connecting everything together

**Inputs I provide:**
- `resource_group_name` - Where to create resources
- `location` - Azure region (I use eastus)
- `environment` - Environment name for tagging and naming
- `vnet_cidr` - The overall IP range (I use 10.0.0.0/16)
- `public_subnet_cidr` - Public subnet range (I use 10.0.1.0/24)
- `private_subnet_cidr` - Private subnet range (I use 10.0.2.0/24)

**What it gives back (outputs):**
- `vnet_id` - The VNet ID (other modules need this)
- `public_subnet_id` - Where to put the Application Gateway
- `private_subnet_id` - Where to put the VMs
- `nat_gateway_id` - For verification/debugging

**How I use it:**
```hcl
module "networking" {
  source = "../../modules/networking/azure"
  
  resource_group_name  = "myapp-dev-rg"
  location            = "eastus"
  environment         = "dev"
  vnet_cidr           = "10.0.0.0/16"
  public_subnet_cidr  = "10.0.1.0/24"
  private_subnet_cidr = "10.0.2.0/24"
}
```

### The Compute Module

This module creates my VMs and bootstraps them with Docker.

**What it creates:**
- Network interfaces for each VM
- Azure Linux VMs (Ubuntu 22.04)
- No public IPs (security by design)
- SSH key authentication
- Cloud-init configuration that:
  - Updates the system
  - Installs Docker
  - Pulls and runs my NGINX container

**Inputs I provide:**
- `resource_group_name` - Same as networking
- `location` - Same as networking
- `environment` - For tagging
- `subnet_id` - From networking module's output
- `vm_count` - How many VMs to create (I usually use 1 for dev, more for prod)
- `vm_size` - Azure VM SKU (I use Standard_D2s_v3)
- `admin_username` - SSH username (I use "azureuser")
- `ssh_public_key` - My public SSH key

**What it gives back:**
- `vm_ids` - List of all VM IDs
- `private_ips` - Private IP addresses (load balancer needs these)
- `vm_names` - VM names for reference

### The Load Balancer Module

This module creates the Application Gateway that handles all incoming traffic.

**What it creates:**
- Public IP address (this is what external users hit)
- Application Gateway with:
  - Frontend IP configuration
  - HTTPS listener on port 443
  - Backend pool (my VM IPs)
  - HTTP settings for backend communication
  - Health probes to check VM health
  - Routing rules connecting it all

**Inputs I provide:**
- `resource_group_name` - Same as before
- `location` - Same as before
- `environment` - For naming
- `subnet_id` - Public subnet from networking module
- `backend_ips` - Private IPs from compute module
- `ssl_certificate_path` - Path to the PFX certificate file

**What it gives back:**
- `app_gateway_dns` - The public DNS name (this is what I access)
- `app_gateway_id` - For debugging
- `public_ip` - The actual IP address

---

## Security Decisions I Made

Security was a primary concern when I designed this. Here's what I implemented:

### Network-Level Security

**No Public IPs On Application Servers:**
I made a conscious decision to keep all VMs in a private subnet with no public IPs. The only way in is through the Application Gateway. If someone compromises the load balancer, they still can't directly access my VMs.

**NAT Gateway For Outbound:**
My VMs need internet access to pull Docker images and install updates. Instead of giving them public IPs, I route all outbound traffic through a NAT Gateway. The VMs can initiate connections outbound, but nothing can initiate connections inbound.

**Network Security Groups:**
I created NSG rules that only allow:
- Port 22 (SSH) - But only from my bastion/management network
- Port 80 (HTTP) - For redirects to HTTPS
- Port 443 (HTTPS) - For actual traffic

Everything else is denied by default.

**Single Entry Point:**
All traffic goes through the Application Gateway. No exceptions. This gives me one place to monitor, log, and control access.

### Access Control

**SSH Keys Only:**
I disabled password authentication completely. SSH key authentication is the only way to access VMs. I keep my private key secure and never commit it to Git.

**No Direct Access:**
Even with SSH keys, I can't SSH directly to the VMs because they have no public IPs. I'd need to set up a bastion host or use Azure Bastion for management access.

**HTTPS Everywhere:**
HTTP requests get redirected to HTTPS. I configured NGINX to do this at the container level, and the Application Gateway also enforces it.

**Encrypted State:**
My Terraform state is stored in Azure Storage with encryption at rest enabled. The state contains sensitive information, so I made sure it's protected.

### SSL/TLS Configuration

**Self-Signed For Dev:**
Right now, I'm using self-signed certificates. Browsers complain, but that's fine for development. I know the warning is expected.

**Production Will Be Different:**
For production, I'll replace these with proper CA-signed certificates from Let's Encrypt or a commercial CA. The infrastructure supports it - I just need to swap the certificate file.

**TLS 1.2+ Only:**
I configured NGINX to only accept TLS 1.2 and 1.3. No old, vulnerable protocols.

**HTTP to HTTPS Redirect:**
Every HTTP request automatically redirects to HTTPS. No plaintext traffic.

---

## The Docker NGINX Setup

Let me explain how I containerized the application.

### Building The Image Locally

If I want to test locally before deploying:

```bash
cd docker
docker build -t nginx-ssl:latest .
```

This builds my custom NGINX image with SSL support.

### Testing It Before Deployment

I can run it locally to make sure everything works:

```bash
# Run container
docker run -d -p 80:80 -p 443:443 nginx-ssl:latest

# Test HTTPS
curl -k https://localhost

# Check logs
docker logs <container-id>

# Stop it when done
docker stop <container-id>
```

### How SSL Certificates Get Generated

Here's the clever part: My `entrypoint.sh` script runs when the container starts. It checks if certificates exist, and if not, generates them:
```bash
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout /etc/nginx/certs/key.pem \
  -out /etc/nginx/certs/cert.pem \
  -subj "/C=US/ST=State/L=City/O=Org/CN=localhost"
```

This means every container gets fresh certificates on startup. In production, I'd mount pre-generated certificates as volumes instead.

---

## When Things Go Wrong

I've hit these issues before. Here's how I solved them:

### Terraform Init Fails
**Symptom:** `terraform init` fails with provider or backend errors.

**What I do:**
```bash
# Clear the Terraform cache
rm -rf .terraform .terraform.lock.hcl

# Re-initialize with upgrade flag
terraform init -upgrade
```

This usually fixes plugin or provider version issues.

### Azure Authentication Problems
**Symptom:** Terraform can't create resources, or I get authentication errors.

**What I do:**
```bash
# Log in again
az login

# Verify I'm on the right subscription
az account show

# Switch if needed
az account set --subscription "YOUR_SUBSCRIPTION_ID"

# Check my environment variables
echo $ARM_CLIENT_ID
echo $ARM_SUBSCRIPTION_ID
```

### Can't Access Application Gateway
**Symptom:** Application Gateway DNS resolves, but I get timeouts or 502 errors.

**What I check:**

First, NSG rules:
```bash
az network nsg rule list \
  --resource-group myapp-dev-rg \
  --nsg-name myapp-dev-nsg \
  --output table
```

Then, backend health:
```bash
az network application-gateway show-backend-health \
  --resource-group myapp-dev-rg \
  --name myapp-dev-appgw
```

If backends show unhealthy, the problem is usually:
- VMs haven't finished bootstrapping yet (wait 5 minutes)
- Docker container isn't running on the VMs
- Health probe path is wrong

### Docker Container Won't Start On VMs
**Symptom:** Application Gateway shows backends as unhealthy.

**What I do:**

I need to SSH to the VM. Since it has no public IP, I use Azure Bastion or set up a jump box. Once I'm in:

```bash
# Check if Docker is running
sudo systemctl status docker

# List running containers
sudo docker ps

# Check container logs
sudo docker logs <container-id>

# If container isn't running, check cloud-init logs
sudo cat /var/log/cloud-init-output.log
```

Common issues:
- Cloud-init hasn't finished yet
- Docker pull failed (network issue)
- Entrypoint script failed to generate certificates

### Useful Debugging Commands

When I need to dig deeper:

```bash
# Enable Terraform debug logging
export TF_LOG=DEBUG
terraform plan 2>&1 | tee debug.log

# Test network connectivity in detail
curl -v -k https://<app-gateway-dns>

# Check DNS resolution
nslookup <app-gateway-dns>

# Azure API debugging
az rest --method get --url <resource-url> --debug
```

---

## What I Get After Deployment

When `terraform apply` finishes successfully, I see these outputs:

```bash
Outputs:

app_gateway_dns = "myapp-dev-appgw-abc123.eastus.cloudapp.azure.com"
vm_private_ips = [
  "10.0.2.4",
]
resource_group_name = "myapp-dev-rg"
vnet_id = "/subscriptions/xxx/virtualNetworks/myapp-dev-vnet"
```

The most important one is `app_gateway_dns`. That's the URL I access:

```
https://myapp-dev-appgw-abc123.eastus.cloudapp.azure.com
```

My browser shows a certificate warning (because it's self-signed), I click "Advanced" → "Proceed", and I'm in.

---

## Tearing It All Down

When I'm done and want to clean up:

### Destroying Everything

I use my destroy script:

```bash
./scripts/destroy.sh dev azure
```

This runs `terraform destroy` and removes all resources. It takes about 5-10 minutes.

If I want to do it manually:

```bash
cd environments/dev
terraform destroy -var-file="terraform.tfvars"
```

Terraform asks for confirmation. Type `yes` and everything gets deleted.

### Cleaning Up The State Backend

If I want to delete the state backend too (usually only when I'm done with the project entirely):

**For Azure:**
```bash
az storage account delete \
  --name tfstate12345 \
  --resource-group terraform-state-rg

az group delete --name terraform-state-rg
```

**For AWS:**
```bash
aws s3 rb s3://terraform-state-bucket-12345 --force
aws dynamodb delete-table --table-name terraform-state-lock
```

---

## Scaling The Infrastructure

I designed this to scale easily. Here's how:

### Adding More VMs (Horizontal Scaling)

I edit `environments/dev/terraform.tfvars`:
```hcl
vm_count = 3  # Changed from 1
```

Then apply:

```bash
cd environments/dev
terraform apply -var-file="terraform.tfvars"
```

Terraform creates 2 new VMs and automatically adds them to the Application Gateway's backend pool. Traffic gets distributed across all 3 VMs.

### Using Bigger VMs (Vertical Scaling)

I edit the same `terraform.tfvars` file:
```hcl
vm_size = "Standard_D4s_v3"  # Upgraded from Standard_D2s_v3
```

Apply the change:

```bash
terraform apply -var-file="terraform.tfvars"
```

Terraform will destroy the old VMs and create new, larger ones. There will be downtime during this change (that's a limitation of vertical scaling).

---

## Deploying To Multiple Regions

For global reach, I can deploy the same infrastructure to multiple Azure regions:

### Setting Up Multi-Region

I create separate environment directories:

```bash
# Deploy to East US
cd environments/prod-eastus
terraform apply

# Deploy to West Europe
cd environments/prod-westeurope
terraform apply

# Deploy to Southeast Asia
cd environments/prod-seasia
terraform apply
```

Each environment has its own:
- Variable file with region-specific settings
- State file (so changes don't conflict)
- Resource naming (to avoid conflicts)

### Adding Global Traffic Management

Once I have multiple regions, I add Azure Traffic Manager or Route 53:

```hcl
resource "azurerm_traffic_manager_profile" "global" {
  name = "myapp-global-tm"
  traffic_routing_method = "Performance"  # Routes to closest region
  
  dns_config {
    relative_name = "myapp-global"
    ttl = 60
  }
}
```

Then I add each Application Gateway as an endpoint. Traffic Manager automatically routes users to the closest healthy region.

---

## Final Thoughts

That's the infrastructure I built. It's modular, secure, scalable, and ready for production (with proper SSL certificates).

The key decisions I made:
- **Security first:** Private subnets, no direct VM access
- **Modularity:** Reusable code that works across environments
- **Scalability:** Easy to add VMs or deploy new regions
- **Automation:** CI/CD pipelines eliminate manual work
- **Multi-cloud ready:** AWS configs are ready to go

If I had to do it again, I'd do it the same way. This architecture has served me well.

---

## Questions or Issues?

If you run into problems:
1. Check the troubleshooting section above
2. Review the Terraform and Azure docs
3. Open an issue in the repository

I tried to make this as comprehensive as possible, but if something's unclear, let me know.

---

**Built by:** Me, manually configured for Azure, with AWS ready to go  
**Last Updated:** 2025-10-07  
**Version:** 1.0.0  
**Infrastructure:** Terraform + Azure + Docker + NGINX
