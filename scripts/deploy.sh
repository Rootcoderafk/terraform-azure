#!/bin/bash

# Terraform Deployment Script
# Usage: ./deploy.sh <environment> <cloud_provider> [action]
# Example: ./deploy.sh dev azure apply

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
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
    print_error "Usage: $0 <environment> <cloud_provider> [action]"
    print_info "Environments: dev, staging, prod"
    print_info "Cloud Providers: azure, aws, both"
    print_info "Actions: plan, apply, destroy (default: apply)"
    exit 1
fi

ENVIRONMENT=$1
CLOUD_PROVIDER=$2
ACTION=${3:-apply}

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

# Validate action
if [[ ! "$ACTION" =~ ^(plan|apply|destroy)$ ]]; then
    print_error "Invalid action. Must be: plan, apply, or destroy"
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

print_info "Deployment Configuration:"
echo "  Environment: $ENVIRONMENT"
echo "  Cloud Provider: $CLOUD_PROVIDER"
echo "  Action: $ACTION"
echo "  Enable Azure: $ENABLE_AZURE"
echo "  Enable AWS: $ENABLE_AWS"
echo "  Working Directory: $ENV_DIR"
echo ""

# Check if environment directory exists
if [ ! -d "$ENV_DIR" ]; then
    print_error "Environment directory not found: $ENV_DIR"
    exit 1
fi

# Change to environment directory
cd "$ENV_DIR"

# Check for required Azure environment variables if Azure is enabled
if [ "$ENABLE_AZURE" == "true" ]; then
    if [ -z "$ARM_CLIENT_ID" ] || [ -z "$ARM_CLIENT_SECRET" ] || [ -z "$ARM_SUBSCRIPTION_ID" ] || [ -z "$ARM_TENANT_ID" ]; then
        print_warning "Azure credentials not set. Checking Azure CLI authentication..."
        if ! az account show &> /dev/null; then
            print_error "Not authenticated with Azure. Please run 'az login' or set environment variables:"
            echo "  - ARM_CLIENT_ID"
            echo "  - ARM_CLIENT_SECRET"
            echo "  - ARM_SUBSCRIPTION_ID"
            echo "  - ARM_TENANT_ID"
            exit 1
        fi
    fi
fi

# Check for required AWS environment variables if AWS is enabled
if [ "$ENABLE_AWS" == "true" ]; then
    if [ -z "$AWS_ACCESS_KEY_ID" ] || [ -z "$AWS_SECRET_ACCESS_KEY" ]; then
        print_error "AWS credentials not set. Please set:"
        echo "  - AWS_ACCESS_KEY_ID"
        echo "  - AWS_SECRET_ACCESS_KEY"
        exit 1
    fi
fi

# Terraform init
print_info "Initializing Terraform..."
terraform init -upgrade

# Terraform validate
print_info "Validating Terraform configuration..."
terraform validate

# Terraform format check
print_info "Checking Terraform formatting..."
terraform fmt -check -recursive || print_warning "Some files are not properly formatted"

# Execute action
case $ACTION in
    plan)
        print_info "Planning Terraform changes..."
        terraform plan \
            -var="enable_azure=$ENABLE_AZURE" \
            -var="enable_aws=$ENABLE_AWS" \
            -var-file=terraform.tfvars
        ;;
    
    apply)
        print_info "Planning Terraform changes..."
        terraform plan \
            -var="enable_azure=$ENABLE_AZURE" \
            -var="enable_aws=$ENABLE_AWS" \
            -var-file=terraform.tfvars \
            -out=tfplan
        
        echo ""
        print_warning "Review the plan above. Press Enter to continue with apply, or Ctrl+C to cancel..."
        read -r
        
        print_info "Applying Terraform changes..."
        terraform apply tfplan
        
        print_info "Deployment completed successfully!"
        echo ""
        print_info "Outputs:"
        terraform output
        ;;
    
    destroy)
        print_warning "⚠️  WARNING: This will DESTROY all infrastructure in $ENVIRONMENT environment!"
        
        if [ "$ENVIRONMENT" == "prod" ]; then
            print_error "Destroying production requires manual confirmation!"
            echo -n "Type 'destroy-prod' to continue: "
            read -r confirm
            if [ "$confirm" != "destroy-prod" ]; then
                print_info "Destroy cancelled."
                exit 0
            fi
        else
            echo -n "Type 'yes' to continue: "
            read -r confirm
            if [ "$confirm" != "yes" ]; then
                print_info "Destroy cancelled."
                exit 0
            fi
        fi
        
        print_info "Destroying infrastructure..."
        terraform destroy \
            -var="enable_azure=$ENABLE_AZURE" \
            -var="enable_aws=$ENABLE_AWS" \
            -var-file=terraform.tfvars \
            -auto-approve
        
        print_info "Infrastructure destroyed successfully!"
        ;;
esac

print_info "Done! ✅"
