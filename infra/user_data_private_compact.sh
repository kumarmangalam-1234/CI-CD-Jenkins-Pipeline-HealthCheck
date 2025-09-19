#!/bin/bash

# Compact user data script for private EC2 instance (Database)
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

# Create application directory
mkdir -p /opt/${project_name}
cd /opt/${project_name}

# Create environment file
cat > .env << EOF
MONGO_INITDB_ROOT_USERNAME=admin
MONGO_INITDB_ROOT_PASSWORD=${MONGO_INITDB_ROOT_PASSWORD}
MONGO_INITDB_DATABASE=${MONGO_INITDB_DATABASE}
EOF

# Create minimal Docker Compose file
cat > docker-compose.yml << 'EOF'
version: '3.8'
services:
  mongodb:
    image: mongo:7.0
    container_name: cicd-mongodb
    restart: unless-stopped
    environment:
      MONGO_INITDB_ROOT_USERNAME: ${MONGO_INITDB_ROOT_USERNAME}
      MONGO_INITDB_ROOT_PASSWORD: ${MONGO_INITDB_ROOT_PASSWORD}
      MONGO_INITDB_DATABASE: ${MONGO_INITDB_DATABASE}
    ports:
      - "27017:27017"
    volumes:
      - mongodb_data:/data/db
    command: mongod --bind_ip_all
volumes:
  mongodb_data:
    driver: local
EOF

# Create database init directory and script
mkdir -p code/database/init
cat > code/database/init/01-init-db.js << 'EOF'
print("Initializing CI/CD Dashboard Database...");
db = db.getSiblingDB('cicd-dashboard');
db.createCollection('pipelines');
db.createCollection('builds');
db.createCollection('metrics');
db.createCollection('alerts');
db.createCollection('health_checks');
db.createCollection('failed_builds');
print("Database initialization completed!");
EOF

# Deploy
docker-compose up -d

# Set ownership
chown -R ec2-user:ec2-user /opt/${project_name}

echo "Private EC2 setup completed" >> /var/log/user-data.log
