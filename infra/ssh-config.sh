#!/bin/bash

# SSH Configuration Helper for CI/CD Dashboard
# This script helps configure SSH access to EC2 instances

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

# Create SSH config file
create_ssh_config() {
    local ssh_config_file="$HOME/.ssh/config"
    local key_path="$HOME/.ssh/cicd-dashboard-key"
    
    print_status "Creating SSH configuration..."
    
    # Backup existing config
    if [ -f "$ssh_config_file" ]; then
        cp "$ssh_config_file" "$ssh_config_file.backup.$(date +%Y%m%d-%H%M%S)"
        print_status "Backed up existing SSH config"
    fi
    
    # Create SSH config entries
    cat >> "$ssh_config_file" << EOF

# CI/CD Dashboard Infrastructure
Host cicd-bastion-1
    HostName $(echo $public_ips | awk '{print $1}')
    User ec2-user
    IdentityFile $key_path
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null

Host cicd-bastion-2
    HostName $(echo $public_ips | awk '{print $2}')
    User ec2-user
    IdentityFile $key_path
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null

Host cicd-database
    HostName $private_ip
    User ec2-user
    IdentityFile $key_path
    ProxyJump cicd-bastion-1
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null

EOF
    
    print_success "SSH configuration created"
}

# Test SSH connections
test_connections() {
    print_status "Testing SSH connections..."
    
    # Test public instances
    for i in 1 2; do
        host="cicd-bastion-$i"
        print_status "Testing connection to $host..."
        if ssh -o ConnectTimeout=10 -o BatchMode=yes "$host" "echo 'Connection successful'" 2>/dev/null; then
            print_success "Connection to $host successful"
        else
            print_warning "Connection to $host failed"
        fi
    done
    
    # Test private instance
    print_status "Testing connection to cicd-database..."
    if ssh -o ConnectTimeout=10 -o BatchMode=yes "cicd-database" "echo 'Connection successful'" 2>/dev/null; then
        print_success "Connection to cicd-database successful"
    else
        print_warning "Connection to cicd-database failed"
    fi
}

# Show connection commands
show_commands() {
    echo
    print_success "SSH Configuration Complete!"
    echo
    echo "You can now connect using:"
    echo
    echo "Public EC2 Instance 1:"
    echo "  ssh cicd-bastion-1"
    echo
    echo "Public EC2 Instance 2:"
    echo "  ssh cicd-bastion-2"
    echo
    echo "Private EC2 Instance (Database):"
    echo "  ssh cicd-database"
    echo
    echo "Or use direct commands:"
    echo
    echo "Public instances:"
    echo "  ssh -i ~/.ssh/cicd-dashboard-key ec2-user@$(echo $public_ips | awk '{print $1}')"
    echo "  ssh -i ~/.ssh/cicd-dashboard-key ec2-user@$(echo $public_ips | awk '{print $2}')"
    echo
    echo "Private instance:"
    echo "  ssh -i ~/.ssh/cicd-dashboard-key -J ec2-user@$(echo $public_ips | awk '{print $1}') ec2-user@$private_ip"
    echo
}

# Main function
main() {
    echo "🔑 CI/CD Dashboard SSH Configuration"
    echo "===================================="
    echo
    
    check_terraform
    get_instance_info
    create_ssh_config
    test_connections
    show_commands
}

# Run main function
main "$@"
