# CI/CD Pipeline Health Dashboard - Project Structure

## 📁 Complete Project Overview

```
Repo-HealthChecker/
├── 📁 backend/                          # Python Flask Backend
│   ├── 📄 app.py                       # Main Flask application
│   ├── 📄 requirements.txt              # Python dependencies
│   └── 📄 Dockerfile                   # Backend container configuration
│
├── 📁 frontend/                         # Node.js Frontend
│   ├── 📄 package.json                 # Node.js dependencies
│   ├── 📄 server.js                    # Express server
│   ├── 📄 Dockerfile                   # Frontend container configuration
│   ├── 📁 views/                       # EJS templates
│   │   └── 📄 dashboard.ejs            # Main dashboard template
│   └── 📁 public/                      # Static assets
│       ├── 📁 css/
│       │   └── 📄 dashboard.css        # Custom styles
│       └── 📁 js/
│           └── 📄 dashboard.js         # Dashboard functionality
│
├── 📁 database/                         # Database configuration
│   └── 📁 init/
│       └── 📄 01-init-db.js            # MongoDB initialization script
│
├── 📁 demo/                             # Demo and testing tools
│   └── 📄 simulate-jenkins.py          # Jenkins data simulator
│
├── 📄 docker-compose.yml               # Multi-container orchestration
├── 📄 start.sh                         # Startup script (executable)
├── 📄 env.example                      # Environment configuration template
├── 📄 README.md                        # Project documentation
└── 📄 PROJECT_STRUCTURE.md             # This file
```

## 🏗️ Architecture Components

### 1. **Backend (Python Flask)**
- **Location**: `backend/`
- **Technology**: Python 3.11, Flask, Flask-SocketIO
- **Features**:
  - RESTful API endpoints
  - WebSocket support for real-time updates
  - Jenkins integration
  - MongoDB data management
  - Prometheus metrics
  - Automated alerting (Slack/Email)
  - Background data collection

### 2. **Frontend (Node.js)**
- **Location**: `frontend/`
- **Technology**: Node.js 18+, Express, EJS, Chart.js
- **Features**:
  - Responsive dashboard UI
  - Real-time data visualization
  - Interactive charts and metrics
  - Bootstrap 5 styling
  - WebSocket client integration

### 3. **Database (MongoDB)**
- **Location**: `database/`
- **Technology**: MongoDB 7.0
- **Collections**:
  - `pipelines`: Pipeline information and status
  - `builds`: Build execution data
  - `metrics`: Aggregated metrics
  - `alerts`: Alert history
  - `health_checks`: System health data

### 4. **Infrastructure (Docker)**
- **Location**: Root directory
- **Technology**: Docker, Docker Compose
- **Services**:
  - MongoDB container
  - Python backend container
  - Node.js frontend container
  - Redis container (caching)
  - Nginx container (optional reverse proxy)

## 🚀 Quick Start Commands

### Using Docker Compose (Recommended)
```bash
# Start all services
./start.sh

# Or manually:
docker-compose up -d

# View logs
docker-compose logs -f

# Stop services
docker-compose down
```

### Local Development
```bash
# Backend
cd backend
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
pip install -r requirements.txt
python app.py

# Frontend
cd frontend
npm install
npm start

# Database
# Start MongoDB locally or use MongoDB Atlas
```

## 🔧 Configuration

### Environment Variables
Copy `env.example` to `.env` and configure:
- **Jenkins**: URL, username, API token
- **Database**: MongoDB connection string
- **Alerting**: Slack webhook, SMTP settings
- **Security**: Secret keys, CORS origins

### Key Endpoints
- **Dashboard**: http://localhost:3000
- **Backend API**: http://localhost:5000
- **Health Check**: http://localhost:5000/health
- **Metrics**: http://localhost:5000/metrics

## 📊 Features Implemented

### ✅ Core Features
- [x] Real-time pipeline monitoring
- [x] Success/failure rate tracking
- [x] Build duration analytics
- [x] Interactive charts and metrics
- [x] Responsive dashboard UI
- [x] WebSocket real-time updates
- [x] MongoDB data persistence
- [x] Docker containerization

### ✅ Advanced Features
- [x] Prometheus metrics export
- [x] Structured logging
- [x] Health check endpoints
- [x] Automated data collection
- [x] Background task scheduling
- [x] Error handling and recovery
- [x] CORS configuration
- [x] Rate limiting support

### ✅ DevOps Features
- [x] Health checks
- [x] Graceful shutdown
- [x] Container health monitoring
- [x] Log aggregation
- [x] Environment-based configuration
- [x] Sample data generation

## 🧪 Testing & Demo

### Simulate Jenkins Data
```bash
# Generate historical data
python demo/simulate-jenkins.py --historical 7

# Start continuous simulation
python demo/simulate-jenkins.py --interval 5

# Single simulation run
python demo/simulate-jenkins.py
```

### Sample Data
The database initialization script includes sample data:
- 5 sample pipelines
- Various build statuses
- Realistic metrics and durations
- Different success rates

## 🔍 Monitoring & Observability

### Health Checks
- **Backend**: `/health` endpoint
- **Frontend**: `/health` endpoint
- **Database**: Connection monitoring
- **Jenkins**: API connectivity

### Metrics
- **Prometheus**: `/metrics` endpoint
- **Custom metrics**: Build counts, durations, success rates
- **System metrics**: Pipeline counts, health status

### Logging
- **Structured logging**: JSON format
- **Log levels**: DEBUG, INFO, WARNING, ERROR
- **Context**: Request tracking, user actions

## 🛡️ Security Features

### Authentication & Authorization
- Environment-based configuration
- Secure credential management
- CORS protection
- Rate limiting support

### Data Protection
- MongoDB authentication
- Secure API endpoints
- Input validation
- Error message sanitization

## 📈 Scalability Considerations

### Horizontal Scaling
- Stateless backend design
- MongoDB sharding support
- Load balancer ready
- Container orchestration ready

### Performance
- Database indexing
- Caching support (Redis)
- Async data collection
- Efficient data queries

## 🚨 Troubleshooting

### Common Issues
1. **Port conflicts**: Check if ports 3000, 5000, 27017 are available
2. **Docker issues**: Ensure Docker and Docker Compose are running
3. **Database connection**: Verify MongoDB credentials and network
4. **Jenkins integration**: Check API token and URL accessibility

### Debug Commands
```bash
# Check service status
docker-compose ps

# View specific service logs
docker-compose logs backend
docker-compose logs frontend
docker-compose logs mongodb

# Access database
docker-compose exec mongodb mongosh

# Restart specific service
docker-compose restart backend
```

## 🔄 Maintenance

### Regular Tasks
- Monitor log files
- Check database performance
- Update dependencies
- Review alert configurations
- Backup database data

### Updates
- Pull latest code
- Rebuild containers: `docker-compose build --no-cache`
- Restart services: `docker-compose up -d`

## 📚 Additional Resources

- **Documentation**: See README.md for detailed setup
- **API Reference**: Backend endpoints documented in app.py
- **Configuration**: Environment variables in env.example
- **Docker**: Container configurations in respective Dockerfiles

---

**🎯 This dashboard provides enterprise-grade CI/CD monitoring with modern engineering practices, real-time observability, and comprehensive alerting capabilities.**

