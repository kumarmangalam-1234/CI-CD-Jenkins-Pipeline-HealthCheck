#!/bin/bash

# User data script for private EC2 instance (Database)
# This script installs Docker and deploys MongoDB

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
# MongoDB Configuration
MONGO_INITDB_ROOT_USERNAME=admin
MONGO_INITDB_ROOT_PASSWORD=${mongodb_password}
MONGO_INITDB_DATABASE=cicd-dashboard
EOF

# Create Docker Compose file for private instance (MongoDB only)
cat > docker-compose.yml << 'EOF'
version: '3.8'

services:
  # MongoDB Database
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
      - ./code/database/init:/docker-entrypoint-initdb.d
    networks:
      - cicd-network
    command: mongod --bind_ip_all

  # MongoDB Express (Optional - for database management)
  mongo-express:
    image: mongo-express:latest
    container_name: cicd-mongo-express
    restart: unless-stopped
    environment:
      ME_CONFIG_MONGODB_ADMINUSERNAME: ${MONGO_INITDB_ROOT_USERNAME}
      ME_CONFIG_MONGODB_ADMINPASSWORD: ${MONGO_INITDB_ROOT_PASSWORD}
      ME_CONFIG_MONGODB_URL: mongodb://${MONGO_INITDB_ROOT_USERNAME}:${MONGO_INITDB_ROOT_PASSWORD}@mongodb:27017/
      ME_CONFIG_BASICAUTH_USERNAME: admin
      ME_CONFIG_BASICAUTH_PASSWORD: admin123
    ports:
      - "8081:8081"
    depends_on:
      - mongodb
    networks:
      - cicd-network

volumes:
  mongodb_data:
    driver: local

networks:
  cicd-network:
    driver: bridge
EOF

# Create database initialization directory
mkdir -p code/database/init

# Create MongoDB initialization script
cat > code/database/init/01-init-db.js << 'EOF'
// MongoDB initialization script for CI/CD Dashboard
// This script runs when the MongoDB container starts

print("🚀 Initializing CI/CD Dashboard Database...");

// Switch to the target database
db = db.getSiblingDB('cicd-dashboard');

// Create collections with proper indexes
print("📊 Creating collections and indexes...");

// Pipelines collection
db.createCollection('pipelines');
db.pipelines.createIndex({ "name": 1 }, { unique: true });
db.pipelines.createIndex({ "last_updated": -1 });
db.pipelines.createIndex({ "color": 1 });

// Builds collection
db.createCollection('builds');
db.builds.createIndex({ "pipeline_name": 1, "build_number": -1 }, { unique: true });
db.builds.createIndex({ "timestamp": -1 });
db.builds.createIndex({ "status": 1 });
db.builds.createIndex({ "pipeline_name": 1, "timestamp": -1 });

// Metrics collection for aggregated data
db.createCollection('metrics');
db.metrics.createIndex({ "pipeline_name": 1, "date": 1 }, { unique: true });
db.metrics.createIndex({ "date": -1 });

// Alerts collection for tracking sent alerts
db.createCollection('alerts');
db.alerts.createIndex({ "pipeline_name": 1, "build_number": 1 }, { unique: true });
db.alerts.createIndex({ "timestamp": -1 });
db.alerts.createIndex({ "type": 1 });

// Health checks collection
db.createCollection('health_checks');
db.health_checks.createIndex({ "timestamp": -1 });
db.health_checks.createIndex({ "service": 1 });

// Failed builds collection
db.createCollection('failed_builds');
db.failed_builds.createIndex({ "pipeline_name": 1, "build_number": 1 }, { unique: true });
db.failed_builds.createIndex({ "timestamp": -1 });

print("✅ Database initialization completed successfully!");

// Insert sample data for development/testing
if (process.env.NODE_ENV === 'development' || process.env.INSERT_SAMPLE_DATA === 'true') {
    print("🧪 Inserting sample data for development...");
    
    // Sample pipeline data
    const samplePipelines = [
        {
            name: "frontend-build",
            url: "https://jenkins.example.com/job/frontend-build",
            color: "blue",
            last_updated: new Date(),
            info: {
                description: "Frontend application build pipeline",
                healthReport: [{ score: 100, description: "Build stability: 100%" }]
            }
        },
        {
            name: "backend-api",
            url: "https://jenkins.example.com/job/backend-api",
            color: "blue",
            last_updated: new Date(),
            info: {
                description: "Backend API build and test pipeline",
                healthReport: [{ score: 95, description: "Build stability: 95%" }]
            }
        },
        {
            name: "integration-tests",
            url: "https://jenkins.example.com/job/integration-tests",
            color: "red",
            last_updated: new Date(),
            info: {
                description: "Integration test suite execution",
                healthReport: [{ score: 80, description: "Build stability: 80%" }]
            }
        }
    ];
    
    db.pipelines.insertMany(samplePipelines);
    
    // Sample build data
    const sampleBuilds = [
        {
            pipeline_name: "frontend-build",
            build_number: 123,
            url: "https://jenkins.example.com/job/frontend-build/123",
            timestamp: new Date(Date.now() - 3600000), // 1 hour ago
            status: "SUCCESS",
            duration: 180, // 3 minutes
            estimated_duration: 200,
            executor: { currentExecutable: { number: 123 } },
            last_updated: new Date(),
            user: "admin"
        },
        {
            pipeline_name: "frontend-build",
            build_number: 122,
            url: "https://jenkins.example.com/job/frontend-build/122",
            timestamp: new Date(Date.now() - 7200000), // 2 hours ago
            status: "SUCCESS",
            duration: 165,
            estimated_duration: 200,
            executor: { currentExecutable: { number: 122 } },
            last_updated: new Date(),
            user: "admin"
        },
        {
            pipeline_name: "backend-api",
            build_number: 89,
            url: "https://jenkins.example.com/job/backend-api/89",
            timestamp: new Date(Date.now() - 1800000), // 30 minutes ago
            status: "SUCCESS",
            duration: 420, // 7 minutes
            estimated_duration: 450,
            executor: { currentExecutable: { number: 89 } },
            last_updated: new Date(),
            user: "admin"
        },
        {
            pipeline_name: "integration-tests",
            build_number: 67,
            url: "https://jenkins.example.com/job/integration-tests/67",
            timestamp: new Date(Date.now() - 900000), // 15 minutes ago
            status: "FAILURE",
            duration: 1200, // 20 minutes
            estimated_duration: 900,
            executor: { currentExecutable: { number: 67 } },
            last_updated: new Date(),
            user: "admin"
        }
    ];
    
    db.builds.insertMany(sampleBuilds);
    
    print("✅ Sample data inserted successfully!");
}

print("🎉 CI/CD Dashboard database is ready!");
print("📈 Collections created: " + db.getCollectionNames().join(", "));
print("🔍 Total pipelines: " + db.pipelines.countDocuments());
print("🔨 Total builds: " + db.builds.countDocuments());
print("📊 Total metrics: " + db.metrics.countDocuments());
EOF

# Create a deployment script
cat > deploy.sh << 'EOF'
#!/bin/bash

# Deployment script for MongoDB

set -e

echo "🚀 Starting deployment of MongoDB..."

# Stop existing containers
docker-compose down || true

# Build and start services
docker-compose up -d

# Wait for MongoDB to be ready
echo "⏳ Waiting for MongoDB to start..."
sleep 30

# Check health
echo "🔍 Checking service health..."
docker-compose ps

# Test MongoDB connection
echo "🧪 Testing MongoDB connection..."
docker exec cicd-mongodb mongosh --eval "db.adminCommand('ping')" || echo "MongoDB connection test failed"

echo "✅ MongoDB deployment completed!"
echo "🗄️  MongoDB: mongodb://admin:${MONGO_INITDB_ROOT_PASSWORD}@localhost:27017/cicd-dashboard?authSource=admin"
echo "🌐 Mongo Express: http://localhost:8081 (admin/admin123)"
EOF

chmod +x deploy.sh

# Create systemd service for auto-start
cat > /etc/systemd/system/cicd-mongodb.service << EOF
[Unit]
Description=CI/CD Dashboard MongoDB
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
systemctl enable cicd-mongodb.service

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
                        "log_group_name": "/aws/ec2/cicd-dashboard-mongodb",
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

# Health check script for MongoDB

MONGODB_URL="mongodb://admin:${MONGO_INITDB_ROOT_PASSWORD}@localhost:27017/cicd-dashboard?authSource=admin"

check_mongodb() {
    if docker exec cicd-mongodb mongosh --eval "db.adminCommand('ping')" > /dev/null 2>&1; then
        echo "✅ MongoDB is healthy"
        return 0
    else
        echo "❌ MongoDB is unhealthy"
        return 1
    fi
}

check_mongo_express() {
    if curl -f -s "http://localhost:8081" > /dev/null; then
        echo "✅ Mongo Express is healthy"
        return 0
    else
        echo "❌ Mongo Express is unhealthy"
        return 1
    fi
}

echo "🔍 Performing health checks..."
check_mongodb
check_mongo_express

# Check Docker containers
echo "🐳 Checking Docker containers..."
docker-compose ps
EOF

chmod +x /opt/${project_name}/health-check.sh

# Create a cron job for health checks
echo "*/5 * * * * ec2-user /opt/${project_name}/health-check.sh >> /var/log/cicd-mongodb-health.log 2>&1" | crontab -u ec2-user -

# Create a backup script
cat > /opt/${project_name}/backup.sh << 'EOF'
#!/bin/bash

# MongoDB backup script

BACKUP_DIR="/opt/${project_name}/backups"
DATE=\$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="mongodb_backup_$${DATE}.gz"

mkdir -p "$BACKUP_DIR"

echo "🗄️  Creating MongoDB backup: $BACKUP_FILE"

docker exec cicd-mongodb mongodump \
    --username=admin \
    --password=${MONGO_INITDB_ROOT_PASSWORD} \
    --authenticationDatabase=admin \
    --db=cicd-dashboard \
    --archive | gzip > "$BACKUP_DIR/$BACKUP_FILE"

if [ $? -eq 0 ]; then
    echo "✅ Backup created successfully: $BACKUP_FILE"
    
    # Keep only last 7 days of backups
    find "$BACKUP_DIR" -name "mongodb_backup_*.gz" -mtime +7 -delete
    
    echo "🧹 Old backups cleaned up"
else
    echo "❌ Backup failed"
    exit 1
fi
EOF

chmod +x /opt/${project_name}/backup.sh

# Create a cron job for daily backups
echo "0 2 * * * ec2-user /opt/${project_name}/backup.sh >> /var/log/cicd-mongodb-backup.log 2>&1" | crontab -u ec2-user -

# Log completion
echo "✅ Private EC2 instance setup completed at $(date)" >> /var/log/user-data.log
