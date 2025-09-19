#!/bin/bash

# Compact user data script for public EC2 instances (Frontend/Backend/Jenkins)
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

# Create application directory
mkdir -p /opt/${project_name}
cd /opt/${project_name}

# Create environment file
cat > .env << EOF
MONGODB_URI=${MONGODB_URI}
JENKINS_URL=http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):8080
JENKINS_USERNAME=${jenkins_username}
JENKINS_API_TOKEN=${jenkins_api_token}
SMTP_HOST=${smtp_host}
SMTP_PORT=${smtp_port}
SMTP_USERNAME=${smtp_username}
SMTP_PASSWORD=${smtp_password}
SLACK_WEBHOOK_URL=${slack_webhook_url}
EOF

# Create minimal Docker Compose file
cat > docker-compose.yml << 'EOF'
version: '3.8'
services:
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
    user: root
    privileged: true

  backend:
    build:
      context: ./code/backend
      dockerfile: Dockerfile
    container_name: cicd-backend
    restart: unless-stopped
    environment:
      - FLASK_ENV=production
      - MONGODB_URI=${MONGODB_URI}
      - JENKINS_URL=http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):8080
      - JENKINS_USERNAME=${JENKINS_USERNAME}
      - JENKINS_API_TOKEN=${JENKINS_API_TOKEN}
      - SLACK_WEBHOOK_URL=${SLACK_WEBHOOK_URL}
      - SMTP_HOST=${SMTP_HOST}
      - SMTP_PORT=${SMTP_PORT}
      - SMTP_USERNAME=${SMTP_USERNAME}
      - SMTP_PASSWORD=${SMTP_PASSWORD}
    ports:
      - "5001:5000"
    depends_on:
      - jenkins

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

volumes:
  jenkins_home:
    driver: local
EOF

# Create directories for application code
mkdir -p code/{backend,frontend}

# Set ownership
chown -R ec2-user:ec2-user /opt/${project_name}

echo "Public EC2 setup completed" >> /var/log/user-data.log
