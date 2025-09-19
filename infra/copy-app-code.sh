#!/bin/bash

# Script to copy application code to EC2 instances after infrastructure deployment

set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
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

# Check if Terraform has been applied
check_terraform() {
    if [ ! -f "terraform.tfstate" ]; then
        print_warning "Terraform state not found. Please run 'terraform apply' first."
        exit 1
    fi
}

# Get instance information
get_instance_info() {
    print_status "Getting instance information..."
    
    # Get public IPs
    public_ips=$(terraform output -json public_ec2_public_ips | jq -r '.[]' 2>/dev/null || echo "")
    private_ip=$(terraform output -json private_ec2_private_ips | jq -r '.[0]' 2>/dev/null || echo "")
    
    if [ -z "$public_ips" ]; then
        print_warning "Could not get instance information. Make sure Terraform has been applied."
        exit 1
    fi
    
    print_success "Instance information retrieved"
}

# Copy application code to instances
copy_application_code() {
    print_status "Copying application code to EC2 instances..."
    
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
            # Cleanup
            rm /tmp/app-deployment.tar.gz
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
            # Cleanup
            rm /tmp/app-deployment.tar.gz
EOF
    
    print_success "Database initialization deployed to $private_ip"
    
    # Cleanup
    rm -rf "$temp_dir" "$temp_dir/../app-deployment.tar.gz"
}

# Main function
main() {
    echo "📦 Application Code Deployment"
    echo "============================="
    echo
    
    check_terraform
    get_instance_info
    copy_application_code
    
    echo
    print_success "Application code deployment completed!"
    echo
    print_status "Next steps:"
    echo "1. Wait 2-3 minutes for services to start"
    echo "2. Run './jenkins-setup.sh' to configure Jenkins"
    echo "3. Test the application URLs"
}

# Run main function
main "$@"
