#!/bin/bash

# Initialize Terraform Backend
# This script sets up the remote state backend for Terraform

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
if [ $# -lt 1 ]; then
    print_error "Usage: $0 <cloud_provider>"
    print_info "Cloud Providers: azure, aws"
    exit 1
fi

CLOUD_PROVIDER=$1

case $CLOUD_PROVIDER in
    azure)
        print_info "Setting up Azure backend for Terraform state..."
        
        # Variables
        RESOURCE_GROUP="terraform-state-rg"
        STORAGE_ACCOUNT="tfstate$(date +%s | tail -c 8)"
        CONTAINER_NAME="tfstate"
        LOCATION="eastus"
        
        # Check Azure CLI authentication
        if ! az account show &> /dev/null; then
            print_error "Not authenticated with Azure. Please run 'az login'"
            exit 1
        fi
        
        print_info "Using storage account name: $STORAGE_ACCOUNT"
        
        # Create resource group
        print_info "Creating resource group: $RESOURCE_GROUP..."
        az group create \
            --name "$RESOURCE_GROUP" \
            --location "$LOCATION" \
            --output table
        
        # Create storage account
        print_info "Creating storage account: $STORAGE_ACCOUNT..."
        az storage account create \
            --name "$STORAGE_ACCOUNT" \
            --resource-group "$RESOURCE_GROUP" \
            --location "$LOCATION" \
            --sku Standard_LRS \
            --encryption-services blob \
            --output table
        
        # Get storage account key
        ACCOUNT_KEY=$(az storage account keys list \
            --resource-group "$RESOURCE_GROUP" \
            --account-name "$STORAGE_ACCOUNT" \
            --query '[0].value' \
            --output tsv)
        
        # Create container
        print_info "Creating container: $CONTAINER_NAME..."
        az storage container create \
            --name "$CONTAINER_NAME" \
            --account-name "$STORAGE_ACCOUNT" \
            --account-key "$ACCOUNT_KEY" \
            --output table
        
        # Enable soft delete (optional but recommended)
        print_info "Enabling blob soft delete..."
        az storage blob service-properties delete-policy update \
            --account-name "$STORAGE_ACCOUNT" \
            --account-key "$ACCOUNT_KEY" \
            --days-retained 30 \
            --enable true
        
        print_info "✅ Azure backend setup complete!"
        echo ""
        print_info "Update your backend.tf with these values:"
        echo "  resource_group_name  = \"$RESOURCE_GROUP\""
        echo "  storage_account_name = \"$STORAGE_ACCOUNT\""
        echo "  container_name       = \"$CONTAINER_NAME\""
        echo "  key                  = \"<environment>.terraform.tfstate\""
        ;;
    
    aws)
        print_info "Setting up AWS backend for Terraform state..."
        
        # Variables
        BUCKET_NAME="terraform-state-$(date +%s)"
        TABLE_NAME="terraform-state-lock"
        REGION="us-east-1"
        
        # Check AWS CLI authentication
        if ! aws sts get-caller-identity &> /dev/null; then
            print_error "Not authenticated with AWS. Please run 'aws configure'"
            exit 1
        fi
        
        print_info "Using bucket name: $BUCKET_NAME"
        
        # Create S3 bucket
        print_info "Creating S3 bucket: $BUCKET_NAME..."
        aws s3api create-bucket \
            --bucket "$BUCKET_NAME" \
            --region "$REGION"
        
        # Enable versioning
        print_info "Enabling bucket versioning..."
        aws s3api put-bucket-versioning \
            --bucket "$BUCKET_NAME" \
            --versioning-configuration Status=Enabled
        
        # Enable encryption
        print_info "Enabling bucket encryption..."
        aws s3api put-bucket-encryption \
            --bucket "$BUCKET_NAME" \
            --server-side-encryption-configuration '{
                "Rules": [{
                    "ApplyServerSideEncryptionByDefault": {
                        "SSEAlgorithm": "AES256"
                    }
                }]
            }'
        
        # Block public access
        print_info "Blocking public access..."
        aws s3api put-public-access-block \
            --bucket "$BUCKET_NAME" \
            --public-access-block-configuration \
            "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"
        
        # Create DynamoDB table for state locking
        print_info "Creating DynamoDB table: $TABLE_NAME..."
        aws dynamodb create-table \
            --table-name "$TABLE_NAME" \
            --attribute-definitions AttributeName=LockID,AttributeType=S \
            --key-schema AttributeName=LockID,KeyType=HASH \
            --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5 \
            --region "$REGION"
        
        print_info "Waiting for table to be created..."
        aws dynamodb wait table-exists --table-name "$TABLE_NAME"
        
        print_info "✅ AWS backend setup complete!"
        echo ""
        print_info "Update your backend.tf with these values:"
        echo "  bucket         = \"$BUCKET_NAME\""
        echo "  key            = \"<environment>/terraform.tfstate\""
        echo "  region         = \"$REGION\""
        echo "  dynamodb_table = \"$TABLE_NAME\""
        echo "  encrypt        = true"
        ;;
    
    *)
        print_error "Invalid cloud provider. Must be: azure or aws"
        exit 1
        ;;
esac
