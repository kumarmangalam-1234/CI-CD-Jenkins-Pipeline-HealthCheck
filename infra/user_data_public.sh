#!/bin/bash

# User data script for public EC2 instances (Frontend/Backend)
# This script installs Docker and deploys the application

set -e

# Update system
yum update -y

# Install Docker
yum install -y docker
systemctl start docker
systemctl enable docker
usermod -a -G docker ec2-user

# Install Docker Compose
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose

# Install Git
yum install -y git

# Install Node.js (for potential local development)
curl -fsSL https://rpm.nodesource.com/setup_18.x | bash -
yum install -y nodejs

# Install Python 3.11
yum install -y python3.11 python3.11-pip

# Create application directory
mkdir -p /opt/${project_name}
cd /opt/${project_name}

# Clone the repository (you'll need to replace this with your actual repo)
# For now, we'll create the directory structure and copy files
mkdir -p code/{backend,frontend,database/init,nginx}

# Create environment file
cat > .env << EOF
# MongoDB Configuration
MONGODB_URI=mongodb://admin:${mongodb_password}@${mongodb_host}:27017/cicd-dashboard?authSource=admin

# Jenkins Configuration
JENKINS_URL=${jenkins_url}
JENKINS_USERNAME=${jenkins_username}
JENKINS_API_TOKEN=${jenkins_api_token}

# Email Configuration
SMTP_HOST=${smtp_host}
SMTP_PORT=${smtp_port}
SMTP_USERNAME=${smtp_username}
SMTP_PASSWORD=${smtp_password}

# Slack Configuration
SLACK_WEBHOOK_URL=${slack_webhook_url}

# Application Configuration
FLASK_ENV=production
NODE_ENV=production
BACKEND_URL=http://backend:5000
PUBLIC_BACKEND_URL=http://localhost:5001
EOF

# Create Docker Compose file for public instances (Frontend + Backend + Jenkins)
cat > docker-compose.yml << 'EOF'
version: '3.8'

services:
  # Jenkins CI/CD Server
  jenkins:
    image: jenkins/jenkins:lts
    container_name: cicd-jenkins
    restart: unless-stopped
    environment:
      - JENKINS_OPTS=--httpPort=8080
      - JAVA_OPTS=-Djenkins.install.runSetupWizard=false
    ports:
      - "8080:8080"
      - "50000:50000"
    volumes:
      - jenkins_home:/var/jenkins_home
      - /var/run/docker.sock:/var/run/docker.sock
      - /usr/bin/docker:/usr/bin/docker
    networks:
      - cicd-network
    user: root
    privileged: true

  # Python Backend API
  backend:
    build:
      context: ./code/backend
      dockerfile: Dockerfile
    container_name: cicd-backend
    restart: unless-stopped
    environment:
      - FLASK_ENV=production
      - MONGODB_URI=${MONGODB_URI}
      - JENKINS_URL=http://jenkins:8080
      - JENKINS_USERNAME=${JENKINS_USERNAME}
      - JENKINS_API_TOKEN=${JENKINS_API_TOKEN}
      - SLACK_WEBHOOK_URL=${SLACK_WEBHOOK_URL}
      - SMTP_HOST=${SMTP_HOST}
      - SMTP_PORT=${SMTP_PORT}
      - SMTP_USERNAME=${SMTP_USERNAME}
      - SMTP_PASSWORD=${SMTP_PASSWORD}
    ports:
      - "5001:5000"
    networks:
      - cicd-network
    volumes:
      - ./code/backend:/app
      - /app/__pycache__
      - ./code/database:/app/database
    depends_on:
      - jenkins

  # Node.js Frontend
  frontend:
    build:
      context: ./code/frontend
      dockerfile: Dockerfile
    container_name: cicd-frontend
    restart: unless-stopped
    environment:
      - NODE_ENV=production
      - BACKEND_URL=http://backend:5000
      - PUBLIC_BACKEND_URL=http://localhost:5001
    ports:
      - "3000:3000"
    depends_on:
      - backend
    networks:
      - cicd-network
    volumes:
      - ./code/frontend:/app
      - /app/node_modules

  # Redis for caching and session management
  redis:
    image: redis:7-alpine
    container_name: cicd-redis
    restart: unless-stopped
    ports:
      - "6379:6379"
    networks:
      - cicd-network

  # Nginx reverse proxy
  nginx:
    image: nginx:alpine
    container_name: cicd-nginx
    restart: unless-stopped
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./code/nginx/nginx.conf:/etc/nginx/nginx.conf
      - ./code/nginx/ssl:/etc/nginx/ssl
    depends_on:
      - frontend
      - backend
      - jenkins
    networks:
      - cicd-network

volumes:
  jenkins_home:
    driver: local

networks:
  cicd-network:
    driver: bridge
EOF

# Create a deployment script
cat > deploy.sh << 'EOF'
#!/bin/bash

# Deployment script for CI/CD Dashboard

set -e

echo "🚀 Starting deployment of CI/CD Dashboard..."

# Stop existing containers
docker-compose down || true

# Build and start services
docker-compose up -d --build

# Wait for services to be ready
echo "⏳ Waiting for services to start..."
sleep 30

# Check health
echo "🔍 Checking service health..."
docker-compose ps

# Test endpoints
echo "🧪 Testing endpoints..."
curl -f http://localhost:3000/health || echo "Frontend health check failed"
curl -f http://localhost:5001/health || echo "Backend health check failed"

echo "✅ Deployment completed!"
echo "🌐 Frontend: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):3000"
echo "🔧 Backend: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):5001"
EOF

chmod +x deploy.sh

# Create a script to copy application files from S3 or Git
cat > setup-app.sh << 'EOF'
#!/bin/bash

# Script to setup application files
# This will be called after the application code is uploaded

set -e

echo "📁 Setting up application files..."

# Create necessary directories
mkdir -p code/{backend,frontend,database/init,nginx}

# Set proper permissions
chown -R ec2-user:ec2-user /opt/${project_name}
chmod -R 755 /opt/${project_name}

echo "✅ Application setup completed!"
EOF

chmod +x setup-app.sh

# Create systemd service for auto-start
cat > /etc/systemd/system/cicd-dashboard.service << EOF
[Unit]
Description=CI/CD Health Dashboard
After=docker.service
Requires=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=/opt/${project_name}
ExecStart=/usr/local/bin/docker-compose up -d
ExecStop=/usr/local/bin/docker-compose down
User=ec2-user
Group=ec2-user

[Install]
WantedBy=multi-user.target
EOF

# Enable the service
systemctl enable cicd-dashboard.service

# Create log rotation for Docker
cat > /etc/logrotate.d/docker << 'EOF'
/var/lib/docker/containers/*/*.log {
    rotate 7
    daily
    compress
    size=1M
    missingok
    delaycompress
    copytruncate
}
EOF

# Install CloudWatch agent for monitoring
yum install -y amazon-cloudwatch-agent

# Create CloudWatch agent configuration
cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json << 'EOF'
{
    "logs": {
        "logs_collected": {
            "files": {
                "collect_list": [
                    {
                        "file_path": "/var/log/messages",
                        "log_group_name": "/aws/ec2/cicd-dashboard",
                        "log_stream_name": "{instance_id}/messages"
                    }
                ]
            }
        }
    },
    "metrics": {
        "namespace": "CWAgent",
        "metrics_collected": {
            "cpu": {
                "measurement": [
                    "cpu_usage_idle",
                    "cpu_usage_iowait",
                    "cpu_usage_user",
                    "cpu_usage_system"
                ],
                "metrics_collection_interval": 60
            },
            "disk": {
                "measurement": [
                    "used_percent"
                ],
                "metrics_collection_interval": 60,
                "resources": [
                    "*"
                ]
            },
            "mem": {
                "measurement": [
                    "mem_used_percent"
                ],
                "metrics_collection_interval": 60
            }
        }
    }
}
EOF

# Start CloudWatch agent
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
    -a fetch-config \
    -m ec2 \
    -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json \
    -s

# Set proper ownership
chown -R ec2-user:ec2-user /opt/${project_name}

# Create a health check script
cat > /opt/${project_name}/health-check.sh << 'EOF'
#!/bin/bash

# Health check script for CI/CD Dashboard

FRONTEND_URL="http://localhost:3000/health"
BACKEND_URL="http://localhost:5001/health"

check_service() {
    local url=$1
    local service=$2
    
    if curl -f -s "$url" > /dev/null; then
        echo "✅ $service is healthy"
        return 0
    else
        echo "❌ $service is unhealthy"
        return 1
    fi
}

echo "🔍 Performing health checks..."
check_service "$FRONTEND_URL" "Frontend"
check_service "$BACKEND_URL" "Backend"

# Check Docker containers
echo "🐳 Checking Docker containers..."
docker-compose ps
EOF

chmod +x /opt/${project_name}/health-check.sh

# Create a cron job for health checks
echo "*/5 * * * * ec2-user /opt/${project_name}/health-check.sh >> /var/log/cicd-health.log 2>&1" | crontab -u ec2-user -

# Log completion
echo "✅ Public EC2 instance setup completed at $(date)" >> /var/log/user-data.log
