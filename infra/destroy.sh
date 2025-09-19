#!/bin/bash

# Destroy script for CI/CD Health Dashboard Infrastructure
# This script destroys the entire infrastructure using Terraform

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if Terraform is initialized
check_terraform() {
    if [ ! -d ".terraform" ]; then
        print_error "Terraform not initialized. Please run 'terraform init' first."
        exit 1
    fi
}

# Backup important data before destruction
backup_data() {
    print_status "Creating backup of important data..."
    
    local backup_dir="backup-$(date +%Y%m%d-%H%M%S)"
    mkdir -p "$backup_dir"
    
    # Get outputs before destruction
    terraform output -json > "$backup_dir/terraform-outputs.json" 2>/dev/null || true
    
    # Save MongoDB password
    terraform output -raw mongodb_password > "$backup_dir/mongodb-password.txt" 2>/dev/null || true
    
    print_success "Backup created in $backup_dir"
    print_warning "Please save any important data from the backup directory before proceeding."
}

# Destroy infrastructure
destroy_infrastructure() {
    print_status "Destroying infrastructure..."
    
    # Plan the destruction
    terraform plan -destroy -out=destroy-plan
    
    echo
    print_warning "Review the destruction plan above."
    read -p "Are you sure you want to destroy all resources? This action cannot be undone! (yes/NO): " -r
    
    if [[ $REPLY == "yes" ]]; then
        terraform apply destroy-plan
        print_success "Infrastructure destroyed successfully!"
    else
        print_status "Destruction cancelled."
        exit 0
    fi
}

# Cleanup local files
cleanup() {
    print_status "Cleaning up local files..."
    
    rm -f tfplan destroy-plan
    rm -f terraform.tfstate.backup
    
    print_success "Local files cleaned up!"
}

# Main function
main() {
    echo "💥 CI/CD Health Dashboard Infrastructure Destruction"
    echo "=================================================="
    echo
    
    check_terraform
    backup_data
    
    echo
    print_warning "This will destroy ALL resources created by Terraform!"
    print_warning "This includes:"
    echo "   - VPC and all subnets"
    echo "   - EC2 instances"
    echo "   - Load balancer"
    echo "   - Security groups"
    echo "   - All data stored in the instances"
    echo
    
    read -p "Are you absolutely sure you want to proceed? (yes/NO): " -r
    
    if [[ $REPLY == "yes" ]]; then
        destroy_infrastructure
        cleanup
        print_success "Infrastructure destruction completed!"
    else
        print_status "Destruction cancelled."
        exit 0
    fi
}

# Run main function
main "$@"
