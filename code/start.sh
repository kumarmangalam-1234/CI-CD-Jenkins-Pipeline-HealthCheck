#!/bin/bash

# CI/CD Pipeline Health Dashboard Startup Script
# This script sets up and starts the entire dashboard system

set -e

echo "🚀 Starting CI/CD Pipeline Health Dashboard..."

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

# Check if Docker is running
check_docker() {
    print_status "Checking Docker status..."
    if ! docker info > /dev/null 2>&1; then
        print_error "Docker is not running. Please start Docker and try again."
        exit 1
    fi
    print_success "Docker is running"
}

# Check if Docker Compose is available
check_docker_compose() {
    print_status "Checking Docker Compose..."
    if ! command -v /usr/local/bin/docker compose &> /dev/null; then
        print_error "Docker Compose is not installed. Please install it and try again."
        exit 1
    fi
    print_success "Docker Compose is available"
}

# Check if .env file exists
check_env_file() {
    print_status "Checking environment configuration..."
    if [ ! -f .env ]; then
        print_warning ".env file not found. Creating from template..."
        if [ -f env.example ]; then
            cp env.example .env
            print_warning "Please edit .env file with your actual configuration values"
            print_warning "Press Enter to continue with default values, or Ctrl+C to edit first..."
            read -r
        else
            print_error "env.example file not found. Cannot create .env file."
            exit 1
        fi
    else
        print_success "Environment configuration found"
    fi
}

# Build and start services
start_services() {
    print_status "Building and starting services..."
    
    # Stop any existing containers
    print_status "Stopping existing containers..."
    /usr/local/bin/docker compose  down --remove-orphans
    
    # Build images
    print_status "Building Docker images..."
    /usr/local/bin/docker compose build --no-cache
    
    # Start services
    print_status "Starting services..."
    /usr/local/bin/docker compose up -d
    
    print_success "Services started successfully"
}

# Wait for services to be ready
wait_for_services() {
    print_status "Waiting for services to be ready..."
    
    # Wait for MongoDB
    print_status "Waiting for MongoDB..."
    until /usr/local/bin/docker compose exec -T mongodb mongosh --eval "db.adminCommand('ping')" > /dev/null 2>&1; do
        sleep 2
    done
    print_success "MongoDB is ready"
    
    # Wait for Backend
    print_status "Waiting for Backend API..."
    until curl -f http://localhost:5000/health > /dev/null 2>&1; do
        sleep 3
    done
    print_success "Backend API is ready"
    
    # Wait for Frontend
    print_status "Waiting for Frontend..."
    until curl -f http://localhost:3000/health > /dev/null 2>&1; do
        sleep 3
    done
    print_success "Frontend is ready"
}

# Show service status
show_status() {
    print_status "Service Status:"
    /usr/local/bin/docker compose ps
    echo ""
    print_status "Service URLs:"
    echo -e "  ${GREEN}Frontend Dashboard:${NC} http://localhost:3000"
    echo -e "  ${GREEN}Backend API:${NC} http://localhost:5000"
    echo -e "  ${GREEN}MongoDB:${NC} localhost:27017"
    echo -e "  ${GREEN}Prometheus Metrics:${NC} http://localhost:5000/metrics"
    echo -e "  ${GREEN}Health Check:${NC} http://localhost:5000/health"
    
    echo ""
    print_status "Container Logs:"
    echo -e "  ${GREEN}View all logs:${NC} docker-compose logs -f"
    echo -e "  ${GREEN}Backend logs:${NC} docker-compose logs -f backend"
    echo -e "  ${GREEN}Frontend logs:${NC} docker-compose logs -f frontend"
    echo -e "  ${GREEN}MongoDB logs:${NC} docker-compose logs -f mongodb"
}

# Main execution
main() {
    echo "=========================================="
    echo "  CI/CD Pipeline Health Dashboard"
    echo "=========================================="
    echo ""
    
    check_docker
    check_docker_compose
    check_env_file
    start_services
    wait_for_services
    
    echo ""
    echo "=========================================="
    print_success "Dashboard is ready!"
    echo "=========================================="
    echo ""
    
    show_status
    
    echo ""
    print_status "To stop the dashboard, run: docker-compose down"
    print_status "To view logs, run: docker-compose logs -f"
    print_status "To restart, run: ./start.sh"
}

# Handle script interruption
trap 'echo -e "\n${YELLOW}[WARNING]${NC} Startup interrupted. Use docker-compose down to stop services."' INT

# Run main function
main "$@"
