#!/bin/bash

# Terraform Destroy Script
# Usage: ./destroy.sh <environment> <cloud_provider>
# Example: ./destroy.sh dev azure

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Check arguments
if [ $# -lt 2 ]; then
    print_error "Usage: $0 <environment> <cloud_provider>"
    print_info "Environments: dev, staging, prod"
    print_info "Cloud Providers: azure, aws, both"
    exit 1
fi

ENVIRONMENT=$1
CLOUD_PROVIDER=$2

# Validate environment
if [[ ! "$ENVIRONMENT" =~ ^(dev|staging|prod)$ ]]; then
    print_error "Invalid environment. Must be: dev, staging, or prod"
    exit 1
fi

# Validate cloud provider
if [[ ! "$CLOUD_PROVIDER" =~ ^(azure|aws|both)$ ]]; then
    print_error "Invalid cloud provider. Must be: azure, aws, or both"
    exit 1
fi

# Set cloud provider flags
ENABLE_AZURE="false"
ENABLE_AWS="false"

if [ "$CLOUD_PROVIDER" == "azure" ] || [ "$CLOUD_PROVIDER" == "both" ]; then
    ENABLE_AZURE="true"
fi

if [ "$CLOUD_PROVIDER" == "aws" ] || [ "$CLOUD_PROVIDER" == "both" ]; then
    ENABLE_AWS="true"
fi

# Set working directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
ENV_DIR="$PROJECT_ROOT/environments/$ENVIRONMENT"

print_warning "⚠️  ⚠️  ⚠️  WARNING ⚠️  ⚠️  ⚠️"
print_warning "This will DESTROY all infrastructure in the $ENVIRONMENT environment!"
print_warning "Cloud Provider: $CLOUD_PROVIDER"
print_warning "This action CANNOT be undone!"
echo ""

if [ "$ENVIRONMENT" == "prod" ]; then
    print_error "🚨 PRODUCTION ENVIRONMENT DESTRUCTION 🚨"
    echo -n "Type 'DESTROY-PRODUCTION-NOW' to confirm: "
    read -r confirm
    if [ "$confirm" != "DESTROY-PRODUCTION-NOW" ]; then
        print_info "Destroy cancelled. No changes were made."
        exit 0
    fi
else
    echo -n "Type 'yes-destroy-$ENVIRONMENT' to confirm: "
    read -r confirm
    if [ "$confirm" != "yes-destroy-$ENVIRONMENT" ]; then
        print_info "Destroy cancelled. No changes were made."
        exit 0
    fi
fi

# Change to environment directory
cd "$ENV_DIR"

# Terraform init
print_info "Initializing Terraform..."
terraform init

# Terraform destroy
print_info "Destroying infrastructure..."
terraform destroy \
    -var="enable_azure=$ENABLE_AZURE" \
    -var="enable_aws=$ENABLE_AWS" \
    -var-file=terraform.tfvars \
    -auto-approve

print_info "✅ Infrastructure destroyed successfully!"

# Optionally clean up state file
echo ""
print_warning "Do you want to remove the state file? (y/N): "
read -r remove_state

if [[ "$remove_state" =~ ^[Yy]$ ]]; then
    print_info "Removing state files..."
    rm -f terraform.tfstate*
    print_info "State files removed."
else
    print_info "State files preserved."
fi

print_info "Done!"
