#!/bin/bash

# Deployment script for CI/CD Health Dashboard Infrastructure
# This script deploys the entire infrastructure using Terraform

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
    
    if ! command -v ssh-keygen &> /dev/null; then
        print_error "SSH keygen is not available. Please install OpenSSH."
        exit 1
    fi
    
    print_success "All prerequisites are met!"
}

# Generate SSH key if it doesn't exist
generate_ssh_key() {
    local key_path="$HOME/.ssh/cicd-dashboard-key"
    
    if [ ! -f "$key_path" ]; then
        print_status "Generating SSH key pair..."
        ssh-keygen -t rsa -b 4096 -f "$key_path" -N "" -C "cicd-dashboard-$(date +%Y%m%d)"
        print_success "SSH key generated at $key_path"
    else
        print_warning "SSH key already exists at $key_path"
    fi
    
    # Set proper permissions
    chmod 600 "$key_path"
    chmod 644 "$key_path.pub"
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

# Copy application code to EC2 instances
deploy_application_code() {
    print_status "Deploying application code to EC2 instances..."
    
    # Get public IPs from Terraform output
    local public_ips=$(terraform output -json public_ec2_public_ips | jq -r '.[]')
    local private_ip=$(terraform output -json private_ec2_private_ips | jq -r '.[0]')
    local key_path="$HOME/.ssh/cicd-dashboard-key"
    
    # Create a temporary directory for the application
    local temp_dir=$(mktemp -d)
    cp -r ../code "$temp_dir/"
    
    # Create a deployment package
    cd "$temp_dir"
    tar -czf ../app-deployment.tar.gz code/
    cd - > /dev/null
    
    # Copy to public EC2 instances
    for ip in $public_ips; do
        print_status "Copying application code to public EC2 instance: $ip"
        
        # Copy the deployment package
        scp -i "$key_path" -o StrictHostKeyChecking=no \
            "$temp_dir/../app-deployment.tar.gz" \
            ec2-user@$ip:/tmp/
        
        # Extract and setup the application
        ssh -i "$key_path" -o StrictHostKeyChecking=no ec2-user@$ip << 'EOF'
            # Create directory if it doesn't exist
            sudo mkdir -p /opt/cicd-dashboard
            sudo chown ec2-user:ec2-user /opt/cicd-dashboard
            cd /opt/cicd-dashboard
            # Extract the application code
            tar -xzf /tmp/app-deployment.tar.gz
            # Start the services
            docker-compose up -d --build
EOF
        
        print_success "Application deployed to $ip"
    done
    
    # Copy database initialization to private EC2 instance
    print_status "Copying database initialization to private EC2 instance: $private_ip"
    
    # We need to copy via the public instance (bastion)
    local bastion_ip=$(echo $public_ips | awk '{print $1}')
    
    scp -i "$key_path" -o StrictHostKeyChecking=no \
        -o ProxyCommand="ssh -i $key_path -o StrictHostKeyChecking=no ec2-user@$bastion_ip -W %h:%p" \
        "$temp_dir/../app-deployment.tar.gz" \
        ec2-user@$private_ip:/tmp/
    
    ssh -i "$key_path" -o StrictHostKeyChecking=no \
        -o ProxyCommand="ssh -i $key_path -o StrictHostKeyChecking=no ec2-user@$bastion_ip -W %h:%p" \
        ec2-user@$private_ip << 'EOF'
            # Create directory if it doesn't exist
            sudo mkdir -p /opt/cicd-dashboard
            sudo chown ec2-user:ec2-user /opt/cicd-dashboard
            cd /opt/cicd-dashboard
            # Extract the application code
            tar -xzf /tmp/app-deployment.tar.gz
            # Start the services
            docker-compose up -d
EOF
    
    print_success "Database initialization deployed to $private_ip"
    
    # Cleanup
    rm -rf "$temp_dir" "$temp_dir/../app-deployment.tar.gz"
}

# Display deployment information
show_deployment_info() {
    print_success "Deployment completed successfully!"
    echo
    echo "🌐 Application URLs:"
    echo "   Frontend: $(terraform output -raw frontend_url)"
    echo "   Backend:  $(terraform output -raw backend_url)"
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
}

# Main deployment function
main() {
    echo "🚀 CI/CD Health Dashboard Infrastructure Deployment"
    echo "=================================================="
    echo
    
    check_prerequisites
    generate_ssh_key
    check_aws_credentials
    
    # Check if terraform.tfvars exists
    if [ ! -f "terraform.tfvars" ]; then
        print_warning "terraform.tfvars not found. Please copy terraform.tfvars.example and update with your values."
        print_status "Creating terraform.tfvars from example..."
        cp terraform.tfvars.example terraform.tfvars
        
        # Update SSH key in terraform.tfvars
        local public_key=$(cat "$HOME/.ssh/cicd-dashboard-key.pub")
        sed -i.bak "s|ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC... your-public-key-here|$public_key|" terraform.tfvars
        rm terraform.tfvars.bak
        
        print_warning "Please update terraform.tfvars with your specific configuration before continuing."
        print_status "Opening terraform.tfvars for editing..."
        ${EDITOR:-nano} terraform.tfvars
        
        read -p "Press Enter to continue with deployment..."
    fi
    
    init_terraform
    plan_terraform
    
    echo
    print_warning "Review the Terraform plan above."
    read -p "Do you want to proceed with the deployment? (y/N): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        apply_terraform
        deploy_application_code
        show_deployment_info
    else
        print_status "Deployment cancelled."
        exit 0
    fi
}

# Run main function
main "$@"
