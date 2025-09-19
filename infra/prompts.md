# CI/CD Health Dashboard Infrastructure - Complete Deployment Prompt

## PROJECT OVERVIEW

You are tasked with deploying a comprehensive CI/CD Health Dashboard infrastructure on AWS. This system provides real-time monitoring of Jenkins pipelines, automated notifications, and a web-based dashboard for DevOps teams.

### System Architecture
- Frontend: Node.js/Express web application with EJS templating
- Backend: Python/Flask REST API with MongoDB integration
- CI/CD: Jenkins LTS with automated pipeline monitoring
- Database: MongoDB with automated backups and monitoring
- Infrastructure: AWS VPC with public/private subnets, security groups, and IAM roles
- Monitoring: CloudWatch integration with health checks and logging

---

## INFRASTRUCTURE SPECIFICATIONS

### Network Architecture
```
VPC: 10.10.0.0/16
├── Public Subnets (2x): 10.10.1.0/27, 10.10.2.0/27 (32 IPs each)
├── Private Subnets (2x): 10.10.3.0/27, 10.10.4.0/27 (32 IPs each)
├── Internet Gateway: Direct internet access for public subnets
├── NAT Gateways (2x): Outbound internet access for private subnets
└── Route Tables: Proper routing for public/private traffic
```

### Compute Resources
- Public EC2: 1x t3.medium (Frontend + Backend + Jenkins + Nginx + Redis)
- Private EC2: 1x t2.micro (MongoDB + Mongo Express)
- Storage: 20GB encrypted EBS volumes (gp3)
- Security: IAM roles with least privilege access

### Application Services
| Service | Port | Purpose | Access |
|---------|------|---------|--------|
| Frontend | 3000 | Web Dashboard | Public |
| Backend API | 5001 | REST API | Public |
| Jenkins | 8080 | CI/CD Server | Public |
| Jenkins Agent | 50000 | Build Agents | Public |
| MongoDB | 27017 | Database | Private Only |
| Mongo Express | 8081 | DB Admin UI | Private Only |
| Nginx | 80/443 | Reverse Proxy | Public |
| Redis | 6379 | Caching | Internal |

---

## DEPLOYMENT WORKFLOW

### Phase 1: Infrastructure Deployment
```bash
# Prerequisites Check
- AWS CLI configured with appropriate credentials
- Terraform >= 1.0 installed
- SSH key pair generated

# Deploy Infrastructure
./deploy-infra-only.sh
```

**What happens:**
1. Validates AWS credentials and Terraform installation
2. Generates SSH key pair automatically
3. Initializes Terraform with AWS provider
4. Creates VPC, subnets, security groups, and EC2 instances
5. Configures IAM roles and policies
6. Outputs connection information and URLs

### Phase 2: Application Deployment
```bash
# Deploy Application Code
./copy-app-code.sh
```

**What happens:**
1. Extracts application code from `../code` directory
2. Creates deployment package (tar.gz)
3. Copies code to public EC2 instance via SCP
4. Sets up Docker containers (Frontend, Backend, Jenkins, Nginx, Redis)
5. Copies database initialization to private EC2 instance
6. Starts all services with Docker Compose

### Phase 3: Jenkins Configuration
```bash
# Configure Jenkins
./jenkins-setup.sh
```

**What happens:**
1. Waits for Jenkins to be fully ready
2. Retrieves initial admin password
3. Provides setup instructions
4. Attempts to create API token automatically
5. Guides through manual configuration if needed

---

## CONFIGURATION REQUIREMENTS

### Required Variables (terraform.tfvars)
```hcl
# AWS Configuration
aws_region = "us-west-2"
environment = "production"
project_name = "cicd-dashboard"

# Network Configuration
vpc_cidr = "10.10.0.0/16"
public_subnet_cidrs = ["10.10.1.0/27", "10.10.2.0/27"]
private_subnet_cidrs = ["10.10.3.0/27", "10.10.4.0/27"]

# EC2 Configuration
instance_type = "t3.medium"
database_instance_type = "t2.micro"

# SSH Configuration (Auto-generated)
ssh_public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC..."

# Jenkins Configuration
jenkins_url = "http://[PUBLIC-IP]:8080"
jenkins_username = "admin"
jenkins_api_token = "CHANGE_ME_AFTER_JENKINS_SETUP"

# Email Configuration (Optional)
smtp_host = "smtp.gmail.com"
smtp_port = 587
smtp_username = "your-email@gmail.com"
smtp_password = "your-app-password"

# Slack Configuration (Optional)
slack_webhook_url = "https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK"
```

### Environment Variables (Auto-configured)
```bash
# Database
MONGODB_URI=mongodb://admin:[PASSWORD]@[PRIVATE-IP]:27017/cicd-dashboard?authSource=admin

# Jenkins Integration
JENKINS_URL=http://[PUBLIC-IP]:8080
JENKINS_USERNAME=admin
JENKINS_API_TOKEN=[TOKEN]

# Notification Services
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USERNAME=your-email@gmail.com
SMTP_PASSWORD=your-app-password
SLACK_WEBHOOK_URL=https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK
```

---

## SECURITY CONFIGURATION

### Security Groups
- Public EC2: HTTP/HTTPS, SSH, Jenkins ports (8080, 50000) from anywhere
- Private EC2: MongoDB (27017) and SSH (22) from public EC2 only
- Egress: All outbound traffic allowed

### IAM Roles & Policies
- EC2 Role: CloudWatch logs, instance metadata access
- Least Privilege: Minimal required permissions
- Encryption: EBS volumes encrypted at rest

### Network Security
- Private Subnets: No direct internet access
- NAT Gateways: Secure outbound internet access
- Database Isolation: MongoDB in private subnet only
- SSH Access: Key-based authentication only

---

## MONITORING & OBSERVABILITY

### Health Checks
- Application Health: `/health` endpoints for all services
- Database Health: MongoDB connection monitoring
- Jenkins Health: API connectivity checks
- System Health: CPU, memory, disk usage monitoring

### Logging
- Application Logs: Docker container logs
- System Logs: EC2 instance logs
- CloudWatch: Centralized logging and monitoring
- Error Tracking: Automated error detection and alerting

### Backup Strategy
- MongoDB: Daily automated backups at 2 AM
- Configuration: Terraform state backup
- Data Retention: 7-day backup retention policy

---

## DEPLOYMENT INSTRUCTIONS

### Step 1: Prerequisites Setup
```bash
# Install required tools
# AWS CLI: https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html
# Terraform: https://developer.hashicorp.com/terraform/downloads

# Configure AWS credentials
aws configure
# Enter: Access Key ID, Secret Access Key, Region (us-west-2), Output format (json)

# Verify AWS access
aws sts get-caller-identity
```

### Step 2: Infrastructure Deployment
```bash
# Navigate to infrastructure directory
cd infra/

# Make scripts executable
chmod +x *.sh

# Deploy infrastructure only
./deploy-infra-only.sh

# Expected output:
# - VPC and networking components
# - EC2 instances with security groups
# - IAM roles and policies
# - Connection information and URLs
```

### Step 3: Application Deployment
```bash
# Wait 5-10 minutes for EC2 instances to initialize
# Then deploy application code
./copy-app-code.sh

# Expected output:
# - Application code copied to EC2 instances
# - Docker containers started
# - Services running and accessible
```

### Step 4: Jenkins Configuration
```bash
# Configure Jenkins
./jenkins-setup.sh

# Manual steps required:
# 1. Access Jenkins at http://[PUBLIC-IP]:8080
# 2. Use initial admin password from script output
# 3. Install suggested plugins
# 4. Create admin user
# 5. Generate API token
# 6. Update terraform.tfvars with new token
```

### Step 5: Verification & Testing
```bash
# Test application endpoints
curl http://[PUBLIC-IP]:3000  # Frontend
curl http://[PUBLIC-IP]:5001/health  # Backend API
curl http://[PUBLIC-IP]:8080  # Jenkins

# Check service status
ssh -i ~/.ssh/cicd-dashboard-key ec2-user@[PUBLIC-IP]
docker-compose ps
```

---

## TROUBLESHOOTING GUIDE

### Common Issues & Solutions

#### 1. SSH Connection Failed
```bash
# Check security groups
aws ec2 describe-security-groups --group-ids [SG-ID]

# Verify key permissions
chmod 600 ~/.ssh/cicd-dashboard-key

# Test connectivity
ssh -i ~/.ssh/cicd-dashboard-key -v ec2-user@[PUBLIC-IP]
```

#### 2. Application Not Starting
```bash
# Check Docker containers
docker-compose ps
docker-compose logs [service-name]

# Check system resources
df -h  # Disk space
free -h  # Memory
top  # CPU usage
```

#### 3. Database Connection Issues
```bash
# Verify MongoDB is running
docker exec cicd-mongodb mongosh --eval "db.adminCommand('ping')"

# Check network connectivity
telnet [PRIVATE-IP] 27017

# Verify environment variables
cat .env | grep MONGODB_URI
```

#### 4. Jenkins Not Accessible
```bash
# Check Jenkins container
docker-compose ps jenkins
docker-compose logs jenkins

# Verify port binding
netstat -tlnp | grep 8080

# Check Jenkins configuration
docker exec cicd-jenkins cat /var/jenkins_home/config.xml
```

#### 5. Frontend Not Loading Data
```bash
# Check backend API
curl http://[PUBLIC-IP]:5001/api/pipelines

# Verify Jenkins integration
curl -u admin:[API-TOKEN] http://[PUBLIC-IP]:8080/api/json

# Check browser console for errors
# Verify CORS configuration
```

---

## COST OPTIMIZATION

### Monthly Cost Estimate (us-west-2)
- EC2 Instances: 1x t3.medium + 1x t2.micro = ~$35
- EBS Storage: 2x 20GB gp3 = ~$8
- Data Transfer: ~$5
- Total: ~$48/month

### Cost Reduction Strategies
1. Development Environment: Use t3.small for public instance
2. Spot Instances: Use spot instances for non-critical workloads
3. Auto-scaling: Implement based on demand
4. Reserved Instances: For production workloads
5. Storage Optimization: Use gp2 instead of gp3 for non-critical data

---

## CLEANUP PROCEDURES

### Complete Infrastructure Destruction
```bash
# Destroy all resources
./destroy.sh

# Manual cleanup
terraform destroy
```

### Selective Resource Cleanup
```bash
# Remove specific resources
terraform destroy -target=aws_instance.public_ec2
terraform destroy -target=aws_instance.private_ec2

# Clean up local files
rm -f tfplan destroy-plan terraform.tfstate.backup
```

---

## ADDITIONAL RESOURCES

### Documentation Files
- `deployments.md` - Complete deployment guide
- `CHANGELOG.md` - Infrastructure evolution history
- `terraform.tfvars.example` - Configuration template

### Scripts Reference
- `deploy-infra-only.sh` - Infrastructure deployment
- `copy-app-code.sh` - Application deployment
- `jenkins-setup.sh` - Jenkins configuration
- `destroy.sh` - Infrastructure cleanup
- `ssh-config.sh` - SSH setup helper

### Key Configuration Files
- `main.tf` - Core infrastructure definition
- `variables.tf` - Input variables
- `outputs.tf` - Output values
- `user_data_public_compact.sh` - Public EC2 setup
- `user_data_private_compact.sh` - Private EC2 setup

---

## SUCCESS CRITERIA

### Infrastructure Deployment
- [ ] VPC with public/private subnets created
- [ ] EC2 instances running and accessible
- [ ] Security groups properly configured
- [ ] IAM roles and policies applied
- [ ] All Terraform outputs available

### Application Deployment
- [ ] Frontend accessible at http://[PUBLIC-IP]:3000
- [ ] Backend API responding at http://[PUBLIC-IP]:5001
- [ ] Jenkins accessible at http://[PUBLIC-IP]:8080
- [ ] MongoDB running in private subnet
- [ ] All Docker containers healthy

### Integration & Functionality
- [ ] Jenkins API token configured
- [ ] Backend successfully connecting to Jenkins
- [ ] Frontend displaying Jenkins pipeline data
- [ ] Database connectivity established
- [ ] Health checks passing

### Security & Monitoring
- [ ] SSH access working with key authentication
- [ ] Database isolated in private subnet
- [ ] CloudWatch logging enabled
- [ ] Backup procedures functional
- [ ] Security groups following least privilege

---

## FINAL NOTES

This infrastructure provides a production-ready CI/CD Health Dashboard with:
- High Availability: Multi-AZ deployment with proper networking
- Security: Private database, encrypted storage, least privilege access
- Scalability: Modular design allowing easy horizontal scaling
- Monitoring: Comprehensive logging and health checks
- Cost Efficiency: Optimized resource allocation and cost management

The deployment process is designed to be idempotent and repeatable, ensuring consistent results across different environments and team members.

**Estimated Total Deployment Time**: 30-45 minutes  
**Required Expertise Level**: Intermediate DevOps/Infrastructure  
**Maintenance Overhead**: Low (automated backups, health checks)  
**Scalability**: High (easy to add more instances or services)