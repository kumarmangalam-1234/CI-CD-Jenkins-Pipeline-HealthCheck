#!/bin/bash

# Jenkins Setup Script for CI/CD Dashboard
# This script helps configure Jenkins after deployment

set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
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

# Check if Terraform has been applied
check_terraform() {
    if [ ! -f "terraform.tfstate" ]; then
        print_warning "Terraform state not found. Please run 'terraform apply' first."
        exit 1
    fi
}

# Get Jenkins URL
get_jenkins_url() {
    jenkins_url=$(terraform output -raw jenkins_url 2>/dev/null || echo "")
    if [ -z "$jenkins_url" ]; then
        print_warning "Could not get Jenkins URL from Terraform output."
        exit 1
    fi
    print_success "Jenkins URL: $jenkins_url"
}

# Wait for Jenkins to be ready
wait_for_jenkins() {
    print_status "Waiting for Jenkins to be ready..."
    
    local max_attempts=30
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        if curl -f -s "$jenkins_url" > /dev/null 2>&1; then
            print_success "Jenkins is ready!"
            return 0
        fi
        
        print_status "Attempt $attempt/$max_attempts - Jenkins not ready yet, waiting 10 seconds..."
        sleep 10
        ((attempt++))
    done
    
    print_error "Jenkins did not become ready within expected time."
    exit 1
}

# Get initial admin password
get_initial_password() {
    print_status "Getting Jenkins initial admin password..."
    
    # Get public IP of first EC2 instance
    local public_ip=$(terraform output -json public_ec2_public_ips | jq -r '.[0]' 2>/dev/null || echo "")
    
    if [ -z "$public_ip" ]; then
        print_error "Could not get public IP from Terraform output."
        exit 1
    fi
    
    # Get the initial password from Jenkins container
    local initial_password=$(ssh -i ~/.ssh/cicd-dashboard-key -o StrictHostKeyChecking=no ec2-user@$public_ip \
        "docker exec cicd-jenkins cat /var/jenkins_home/secrets/initialAdminPassword" 2>/dev/null || echo "")
    
    if [ -z "$initial_password" ]; then
        print_warning "Could not retrieve initial admin password. You may need to check Jenkins manually."
        return 1
    fi
    
    print_success "Initial admin password: $initial_password"
    echo
    print_warning "Please save this password securely!"
    echo
    return 0
}

# Create Jenkins API token
create_api_token() {
    print_status "Creating Jenkins API token..."
    
    local public_ip=$(terraform output -json public_ec2_public_ips | jq -r '.[0]' 2>/dev/null || echo "")
    
    if [ -z "$public_ip" ]; then
        print_error "Could not get public IP from Terraform output."
        exit 1
    fi
    
    # Create API token using Jenkins CLI
    local api_token=$(ssh -i ~/.ssh/cicd-dashboard-key -o StrictHostKeyChecking=no ec2-user@$public_ip << 'EOF'
        # Wait for Jenkins to be fully ready
        sleep 30
        
        # Create API token
        docker exec cicd-jenkins java -jar /usr/share/jenkins/jenkins.war -s http://localhost:8080 -auth admin:admin create-token --username admin --token-name "cicd-dashboard-token" 2>/dev/null || echo "TOKEN_CREATION_FAILED"
EOF
    )
    
    if [ "$api_token" = "TOKEN_CREATION_FAILED" ] || [ -z "$api_token" ]; then
        print_warning "Could not create API token automatically. You'll need to create it manually."
        print_status "To create manually:"
        echo "1. Go to $jenkins_url"
        echo "2. Login with admin / [initial-password]"
        echo "3. Go to Manage Jenkins > Manage Users > admin > Configure"
        echo "4. Create new API token"
        echo "5. Update terraform.tfvars with the new token"
        return 1
    fi
    
    print_success "API token created: $api_token"
    echo
    print_warning "Please update terraform.tfvars with this token:"
    echo "jenkins_api_token = \"$api_token\""
    echo
    return 0
}

# Show setup instructions
show_setup_instructions() {
    echo
    print_success "Jenkins Setup Instructions"
    echo "=============================="
    echo
    echo "1. Access Jenkins:"
    echo "   URL: $jenkins_url"
    echo
    echo "2. Initial Setup:"
    echo "   - Use the initial admin password shown above"
    echo "   - Install suggested plugins"
    echo "   - Create admin user (or continue with default)"
    echo
    echo "3. Create API Token:"
    echo "   - Go to Manage Jenkins > Manage Users > admin > Configure"
    echo "   - Click 'Add new Token'"
    echo "   - Name: cicd-dashboard-token"
    echo "   - Copy the generated token"
    echo
    echo "4. Update Configuration:"
    echo "   - Update terraform.tfvars with the new API token"
    echo "   - Restart the backend service: docker-compose restart backend"
    echo
    echo "5. Test Integration:"
    echo "   - Check backend health: curl http://[ALB-DNS]/api/health"
    echo "   - Verify Jenkins connection in backend logs"
    echo
}

# Main function
main() {
    echo "🔧 Jenkins Setup for CI/CD Dashboard"
    echo "===================================="
    echo
    
    check_terraform
    get_jenkins_url
    wait_for_jenkins
    get_initial_password
    show_setup_instructions
    
    echo
    print_status "Jenkins setup completed!"
    print_warning "Remember to update the API token in terraform.tfvars after creating it."
}

# Run main function
main "$@"
