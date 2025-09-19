#!/bin/bash

# Infrastructure-only deployment script
# This script only deploys the AWS infrastructure without copying application code

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

# Check if required tools are installed
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    if ! command -v terraform &> /dev/null; then
        print_error "Terraform is not installed. Please install Terraform first."
        exit 1
    fi
    
    if ! command -v aws &> /dev/null; then
        print_error "AWS CLI is not installed. Please install AWS CLI first."
        exit 1
    fi
    
    print_success "All prerequisites are met!"
}

# Check AWS credentials
check_aws_credentials() {
    print_status "Checking AWS credentials..."
    
    if ! aws sts get-caller-identity &> /dev/null; then
        print_error "AWS credentials not configured. Please run 'aws configure' first."
        exit 1
    fi
    
    local account_id=$(aws sts get-caller-identity --query Account --output text)
    local region=$(aws configure get region)
    
    print_success "AWS credentials configured for account: $account_id in region: $region"
}

# Initialize Terraform
init_terraform() {
    print_status "Initializing Terraform..."
    terraform init
    print_success "Terraform initialized!"
}

# Plan Terraform deployment
plan_terraform() {
    print_status "Planning Terraform deployment..."
    terraform plan -out=tfplan
    print_success "Terraform plan created!"
}

# Apply Terraform deployment
apply_terraform() {
    print_status "Applying Terraform deployment..."
    terraform apply tfplan
    print_success "Terraform deployment completed!"
}

# Display deployment information
show_deployment_info() {
    print_success "Infrastructure deployment completed successfully!"
    echo
    echo "🌐 Application URLs:"
    echo "   Frontend: $(terraform output -raw frontend_url)"
    echo "   Backend:  $(terraform output -raw backend_url)"
    echo "   Jenkins:  $(terraform output -raw jenkins_url)"
    echo
    echo "🔑 SSH Access:"
    echo "   Public EC2: $(terraform output -raw ssh_connection_public)"
    echo "   Private EC2: $(terraform output -raw ssh_connection_private)"
    echo
    echo "🗄️  Database:"
    echo "   MongoDB Password: $(terraform output -raw mongodb_password)"
    echo
    echo "📊 Load Balancer:"
    echo "   DNS Name: $(terraform output -raw alb_dns_name)"
    echo
    print_warning "Please save the MongoDB password securely!"
    echo
    print_status "Next steps:"
    echo "1. Wait 5-10 minutes for EC2 instances to fully initialize"
    echo "2. Copy your application code to the instances manually"
    echo "3. Run './jenkins-setup.sh' to configure Jenkins"
    echo "4. Update Jenkins API token in terraform.tfvars"
}

# Main deployment function
main() {
    echo "🚀 CI/CD Health Dashboard Infrastructure Deployment (Infrastructure Only)"
    echo "========================================================================"
    echo
    
    check_prerequisites
    check_aws_credentials
    
    # Check if terraform.tfvars exists
    if [ ! -f "terraform.tfvars" ]; then
        print_warning "terraform.tfvars not found. Please copy terraform.tfvars.example and update with your values."
        exit 1
    fi
    
    init_terraform
    plan_terraform
    
    echo
    print_warning "Review the Terraform plan above."
    read -p "Do you want to proceed with the deployment? (y/N): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        apply_terraform
        show_deployment_info
    else
        print_status "Deployment cancelled."
        exit 0
    fi
}

# Run main function
main "$@"
