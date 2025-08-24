# CI/CD Pipeline Health Dashboard

A modern, production-ready dashboard for monitoring CI/CD pipeline health with real-time metrics, automated alerting, and comprehensive observability.

## 🚀 Features

- **Real-time Pipeline Monitoring**: Track Jenkins pipeline executions with live updates
- **Comprehensive Metrics**: Success/failure rates, build times, and status tracking
- **Smart Alerting**: Automated notifications via Slack and Email on pipeline failures
- **Modern UI**: Clean, responsive dashboard with real-time charts and metrics
- **Scalable Architecture**: Microservices-based design with MongoDB backend

## 🏗️ Architecture

```
Frontend (Node.js + Express + EJS) → Backend (Python Flask) → MongoDB
                                    ↓
                              Jenkins API Integration
                                    ↓
                              Alerting Service (Slack/Email)
```

## 🛠️ Tech Stack

- **Frontend**: Node.js, Express, EJS, Chart.js, Bootstrap 5
- **Backend**: Python Flask, Flask-SocketIO
- **Database**: MongoDB with Mongoose ODM
- **Real-time**: WebSocket connections for live updates
- **Containerization**: Docker & Docker Compose
- **Monitoring**: Built-in health checks and logging

## 🚀 Quick Start

### Prerequisites
- Docker & Docker Compose
- Node.js 18+ (for local development)
- Python 3.9+ (for local development)

### Using Docker (Recommended)
```bash
# Clone and start all services
git clone <repository>
cd Repo-HealthChecker
docker-compose up -d

# Access the dashboard
open http://localhost:3000
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

## 📊 Dashboard Features

- **Pipeline Overview**: Real-time status of all pipelines
- **Metrics Dashboard**: Success rates, build times, failure trends
- **Build History**: Detailed logs and execution history
- **Alert Management**: Configure and manage notification rules
- **Health Monitoring**: System health and performance metrics

## 🔧 Configuration

### Environment Variables
```bash
# Backend
JENKINS_URL=https://jenkins_url
JENKINS_USERNAME=you_username
JENKINS_API_TOKEN=jenkins_api_token

# Database
MONGODB_URI=mongodb://localhost:27017/cicd-dashboard

# Alerting
SLACK_WEBHOOK_URL=your-slack-webhook
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USERNAME=your-email
SMTP_PASSWORD=your-app-password
```

## 📈 Monitoring & Observability

- **Health Checks**: Built-in endpoint monitoring
- **Logging**: Structured logging with different levels
- **Metrics**: Prometheus-compatible metrics endpoint
- **Error Tracking**: Comprehensive error handling and reporting

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests
5. Submit a pull request

## 📄 License

MIT License - see LICENSE file for details

## 🆘 Support

For issues and questions:
- Create an issue in the repository
- Check the documentation in `/docs`
- Review the troubleshooting guide

---


