#!/usr/bin/env python3
"""
CI/CD Pipeline Health Dashboard Backend
Main Flask application with Jenkins integration and real-time monitoring
"""

import os
import json
import logging
from datetime import datetime, timedelta
from typing import Dict, List, Optional

from flask import Flask, request, jsonify, render_template
from flask_socketio import SocketIO, emit
from flask_cors import CORS
import pymongo
from pymongo import MongoClient
import requests
import schedule
import time
import threading
from prometheus_client import generate_latest, Counter, Histogram, Gauge
import structlog
import smtplib
from email.mime.text import MIMEText

# ...existing code...

# Place this route after Flask app initialization

#!/usr/bin/env python3
"""
CI/CD Pipeline Health Dashboard Backend
Main Flask application with Jenkins integration and real-time monitoring
"""

import os
import json
import logging
from datetime import datetime, timedelta
from typing import Dict, List, Optional

from flask import Flask, request, jsonify, render_template
from flask_socketio import SocketIO, emit
from flask_cors import CORS
import pymongo
from pymongo import MongoClient
import requests
import schedule
import time
import threading
from prometheus_client import generate_latest, Counter, Histogram, Gauge
import structlog
import smtplib
from email.mime.text import MIMEText

# Configure structured logging
structlog.configure(
    processors=[
        structlog.stdlib.filter_by_level,
        structlog.stdlib.add_logger_name,
        structlog.stdlib.add_log_level,
        structlog.stdlib.PositionalArgumentsFormatter(),
        structlog.processors.TimeStamper(fmt="iso"),
        structlog.processors.StackInfoRenderer(),
        structlog.processors.format_exc_info,
        structlog.processors.UnicodeDecoder(),
        structlog.processors.JSONRenderer()
    ],
    context_class=dict,
    logger_factory=structlog.stdlib.LoggerFactory(),
    wrapper_class=structlog.stdlib.BoundLogger,
    cache_logger_on_first_use=True,
)

logger = structlog.get_logger()

# Initialize Flask app
app = Flask(__name__)
app.config['SECRET_KEY'] = os.environ.get('SECRET_KEY', 'dev-secret-key')
CORS(app)
socketio = SocketIO(app, cors_allowed_origins="*")
_bg_started = False

# MongoDB connection
MONGODB_URI = os.environ.get('MONGODB_URI', 'mongodb://localhost:27017/cicd-dashboard')
client = MongoClient(MONGODB_URI)
db = client.get_database()

# Jenkins configuration
JENKINS_URL = os.environ.get('JENKINS_URL', 'https://jenkins.example.com')
JENKINS_USERNAME = os.environ.get('JENKINS_USERNAME', 'admin')
JENKINS_API_TOKEN = os.environ.get('JENKINS_API_TOKEN', 'your-token')

# Alerting configuration
SLACK_WEBHOOK_URL = os.environ.get('SLACK_WEBHOOK_URL')
SMTP_CONFIG = {
    'host': os.environ.get('SMTP_HOST', 'smtp.gmail.com'),
    'port': int(os.environ.get('SMTP_PORT', 587)),
    'username': os.environ.get('SMTP_USERNAME'),
    'password': os.environ.get('SMTP_PASSWORD')
}

# Prometheus metrics
BUILD_COUNTER = Counter('jenkins_builds_total', 'Total Jenkins builds', ['status'])
BUILD_DURATION = Histogram('jenkins_build_duration_seconds', 'Jenkins build duration in seconds')
PIPELINE_GAUGE = Gauge('jenkins_pipelines_active', 'Number of active pipelines')

class JenkinsMonitor:
    """Monitor Jenkins pipelines and collect build data"""
    
    def __init__(self):
        self.session = requests.Session()
        self.session.auth = (JENKINS_USERNAME, JENKINS_API_TOKEN)
        self.session.headers.update({'User-Agent': 'CI-CD-Health-Dashboard/1.0'})
    
    def get_pipelines(self) -> List[Dict]:
        """Get all available pipelines from Jenkins"""
        try:
            response = self.session.get(f"{JENKINS_URL}/api/json?tree=jobs[name,url,color]")
            response.raise_for_status()
            data = response.json()
            return data.get('jobs', [])
        except Exception as e:
            logger.error("Failed to fetch Jenkins pipelines", error=str(e))
            return []
    
    def get_pipeline_info(self, pipeline_name: str) -> Optional[Dict]:
        """Get detailed information about a specific pipeline"""
        try:
            url = f"{JENKINS_URL}/job/{pipeline_name}/api/json"
            response = self.session.get(url)
            response.raise_for_status()
            return response.json()
        except Exception as e:
            logger.error(f"Failed to fetch pipeline info for {pipeline_name}", error=str(e))
            return None
    
    def get_build_info(self, pipeline_name: str, build_number: int) -> Optional[Dict]:
        """Get information about a specific build"""
        try:
            url = f"{JENKINS_URL}/job/{pipeline_name}/{build_number}/api/json"
            response = self.session.get(url)
            response.raise_for_status()
            return response.json()
        except Exception as e:
            logger.error(f"Failed to fetch build info for {pipeline_name}#{build_number}", error=str(e))
            return None
    
    def get_latest_builds(self, pipeline_name: str, limit: int = 100) -> List[Dict]:
        """Get the latest builds for a pipeline"""
        try:
            url = f"{JENKINS_URL}/job/{pipeline_name}/api/json?tree=builds[number,url,timestamp,result,duration,estimatedDuration,executor]"
            response = self.session.get(url)
            response.raise_for_status()
            data = response.json()
            builds = data.get('builds', [])
            return builds[:limit]
        except Exception as e:
            logger.error(f"Failed to fetch latest builds for {pipeline_name}", error=str(e))
            return []

class AlertManager:
    """Manage alerts for pipeline failures"""
    
    def __init__(self):
        self.failure_threshold = 3  # Alert after 3 consecutive failures
    
    def send_slack_alert(self, pipeline_name: str, build_number: int, error_message: str):
        """Send alert to Slack"""
        if not SLACK_WEBHOOK_URL:
            return
        
        try:
            payload = {
                "text": f"🚨 Pipeline Failure Alert",
                "attachments": [{
                    "color": "danger",
                    "fields": [
                        {"title": "Pipeline", "value": pipeline_name, "short": True},
                        {"title": "Build", "value": f"#{build_number}", "short": True},
                        {"title": "Error", "value": error_message, "short": False},
                        {"title": "Time", "value": datetime.now().strftime("%Y-%m-%d %H:%M:%S"), "short": True}
                    ]
                }]
            }
            
            response = requests.post(SLACK_WEBHOOK_URL, json=payload)
            response.raise_for_status()
            logger.info(f"Slack alert sent for {pipeline_name}#{build_number}")
        except Exception as e:
            logger.error(f"Failed to send Slack alert", error=str(e))
    
    def send_email_alert(self, pipeline_name: str, build_number: int, error_message: str):
        """Send alert via email"""
        if not all([SMTP_CONFIG['username'], SMTP_CONFIG['password']]):
            return
        
        try:
            # This would integrate with Flask-Mail for email sending
            logger.info(f"Email alert would be sent for {pipeline_name}#{build_number}")
        except Exception as e:
            logger.error(f"Failed to send email alert", error=str(e))

class DatabaseManager:
    """Manage database operations for pipeline data"""
    
    def __init__(self):
        self.pipelines_collection = db.pipelines
        self.builds_collection = db.builds
        self.metrics_collection = db.metrics
        
        # Create indexes for better performance (use explicit names/uniqueness to avoid conflicts)
        self.builds_collection.create_index(
            [("pipeline_name", 1), ("build_number", -1)],
            name="pipeline_name_1_build_number_-1",
            unique=True
        )
        self.builds_collection.create_index([("timestamp", -1)], name="timestamp_-1")
        self.builds_collection.create_index([("status", 1)], name="status_1")
    
    def save_pipeline(self, pipeline_data: Dict):
        """Save or update pipeline information"""
        try:
            self.pipelines_collection.update_one(
                {"name": pipeline_data["name"]},
                {"$set": pipeline_data},
                upsert=True
            )
        except Exception as e:
            logger.error(f"Failed to save pipeline {pipeline_data.get('name')}", error=str(e))
    
    def save_build(self, build_data: Dict):
        """Save build information"""
        try:
            self.builds_collection.update_one(
                {"pipeline_name": build_data["pipeline_name"], "build_number": build_data["build_number"]},
                {"$set": build_data},
                upsert=True
            )
        except Exception as e:
            logger.error(f"Failed to save build", error=str(e))
    
    def get_pipeline_metrics(self, pipeline_name: str, days: int = 30) -> Dict:
        """Get metrics for a specific pipeline"""
        try:
            cutoff_date = datetime.now() - timedelta(days=days)
            
            pipeline_builds = list(self.builds_collection.find({
                "pipeline_name": pipeline_name,
                "timestamp": {"$gte": cutoff_date}
            }))
            
            if not pipeline_builds:
                return {"total": 0, "success": 0, "failure": 0, "avg_duration": 0}
            
            total = len(pipeline_builds)
            success = len([b for b in pipeline_builds if b.get("status") == "SUCCESS"])
            failure = len([b for b in pipeline_builds if b.get("status") == "FAILURE"])
            
            durations = [b.get("duration", 0) for b in pipeline_builds if b.get("duration")]
            avg_duration = sum(durations) / len(durations) if durations else 0
            
            return {
                "total": total,
                "success": success,
                "failure": failure,
                "success_rate": (success / total) * 100 if total > 0 else 0,
                "avg_duration": avg_duration
            }
        except Exception as e:
            logger.error(f"Failed to get metrics for {pipeline_name}", error=str(e))
            return {}
    
    def get_overall_metrics(self, days: int = 30) -> Dict:
        """Get overall metrics across all pipelines"""
        try:
            cutoff_date = datetime.now() - timedelta(days=days)
            
            all_builds = list(self.builds_collection.find({
                "timestamp": {"$gte": cutoff_date}
            }))
            
            if not all_builds:
                return {"total": 0, "success": 0, "failure": 0, "avg_duration": 0}
            
            total = len(all_builds)
            success = len([b for b in all_builds if b.get("status") == "SUCCESS"])
            failure = len([b for b in all_builds if b.get("status") == "FAILURE"])
            
            durations = [b.get("duration", 0) for b in all_builds if b.get("duration")]
            avg_duration = sum(durations) / len(durations) if durations else 0
            
            return {
                "total": total,
                "success": success,
                "failure": failure,
                "success_rate": (success / total) * 100 if total > 0 else 0,
                "avg_duration": avg_duration
            }
        except Exception as e:
            logger.error("Failed to get overall metrics", error=str(e))
            return {}
    
    def get_recent_failures(self, pipeline_name: Optional[str] = None, limit: int = 10) -> List[Dict]:
        """Return recent failed builds for all or a specific pipeline"""
        query = {"status": "FAILURE"}
        if pipeline_name:
            query["pipeline_name"] = pipeline_name
        return list(self.builds_collection.find(query, {"_id": 0}).sort("timestamp", -1).limit(limit))

def generate_advice(metrics: Dict, recent_failures: List[Dict]) -> List[str]:
    """Generate build time improvement and failure remediation advice."""
    advice: List[str] = []
    success_rate = metrics.get("success_rate", 0)
    avg_duration = metrics.get("avg_duration", 0)

    if success_rate < 80:
        advice.append("Investigate flaky tests; quarantine or fix consistently failing suites.")
        advice.append("Enable 'retry' on transient steps (network/artifact fetch).")
        advice.append("Add early-fail guards and clearer stage-level timeouts.")
    elif success_rate < 95:
        advice.append("Track recent failures by owner; enforce code owners for critical stages.")

    if avg_duration > 600:
        advice.append("Parallelize test execution (e.g., split by timing, sharding).")
        advice.append("Cache dependencies (npm/pip/maven) and Docker layers across builds.")
        advice.append("Skip unchanged stages via checksum-based or path-based triggers.")
    elif avg_duration > 300:
        advice.append("Pre-build base images and reuse across jobs to cut cold-start time.")

    if recent_failures:
        advice.append("Examine last failed build console and stage timings for hotspots.")
        advice.append("Add alerts to the owning Slack channel for immediate triage.")

    if not advice:
        advice.append("Pipelines are healthy. Maintain by monitoring alerts and keeping caches warm.")

    return advice

def generate_resources(recent_failures: List[Dict], pipeline_name: Optional[str] = None) -> List[Dict]:
    """Return helpful external documentation links and direct build console links."""
    resources: List[Dict] = []

    # Direct links to last failed builds
    for f in recent_failures[:3]:
        if f.get('url'):
            resources.append({
                'title': f"Console log: {f.get('pipeline_name')} #{f.get('build_number')}",
                'url': f["url"] + "console"
            })

    # Curated documentation
    resources.extend([
        {
            'title': 'Jenkins Pipeline: Troubleshooting',
            'url': 'https://www.jenkins.io/doc/book/pipeline/troubleshooting/'
        },
        {
            'title': 'Jenkins Declarative Pipeline Syntax',
            'url': 'https://www.jenkins.io/doc/book/pipeline/syntax/'
        },
        {
            'title': 'Retry step for transient failures',
            'url': 'https://www.jenkins.io/doc/pipeline/steps/workflow-basic-steps/#retry-retry-the-body-up-to-n-times'
        },
        {
            'title': 'Parallel stages to speed up builds',
            'url': 'https://www.jenkins.io/doc/book/pipeline/syntax/#parallel'
        },
        {
            'title': 'Archiving and test reports (JUnit)',
            'url': 'https://www.jenkins.io/doc/pipeline/steps/junit/'
        },
        {
            'title': 'Caching dependencies and Docker layers',
            'url': 'https://docs.docker.com/build/cache/'
        },
        {
            'title': 'Stash/Unstash to reuse workspace data',
            'url': 'https://www.jenkins.io/doc/pipeline/steps/workflow-basic-steps/#stash-stash-some-files-to-be-used-later-by-unstash'
        }
    ])

    return resources

# Initialize managers
jenkins_monitor = JenkinsMonitor()
alert_manager = AlertManager()
db_manager = DatabaseManager()

def collect_pipeline_data():
    """Collect data from Jenkins and update database"""
    try:
        logger.info("Starting pipeline data collection")
        pipelines = jenkins_monitor.get_pipelines()
        for pipeline in pipelines:
            pipeline_name = pipeline['name']
            pipeline_info = jenkins_monitor.get_pipeline_info(pipeline_name)
            if pipeline_info:
                db_manager.save_pipeline({
                    "name": pipeline_name,
                    "url": pipeline['url'],
                    "color": pipeline['color'],
                    "last_updated": datetime.now(),
                    "info": pipeline_info
                })
            builds = jenkins_monitor.get_latest_builds(pipeline_name, limit=100)  # Fetch up to 100 recent builds per pipeline
            for build in builds:
                try:
                    user = build.get('causes', [{}])[0].get('userName', '').strip()
                    if not user:
                        user = 'admin'
                    # Debug: Print build number, status, and result
                    logger.info(f"Processing build: pipeline={pipeline_name}, build_number={build.get('number')}, result={build.get('result')}, status={build.get('result', 'UNKNOWN')}")
                    build_data = {
                        "pipeline_name": str(pipeline_name),
                        "build_number": build.get('number'),
                        "url": build.get('url'),
                        "timestamp": datetime.fromtimestamp(build.get('timestamp', 0) / 1000),
                        "status": build.get('result', 'UNKNOWN'),
                        "duration": build.get('duration', 0) / 1000,
                        "estimated_duration": build.get('estimatedDuration', 0) / 1000,
                        "executor": build.get('executor', {}),
                        "last_updated": datetime.now(),
                        "user": user
                    }
                    db_manager.save_build(build_data)
                    BUILD_COUNTER.labels(status=build_data['status']).inc()
                    if build_data['duration'] > 0:
                        BUILD_DURATION.observe(build_data['duration'])
                    # Track failed builds in a separate collection
                    if build_data['status'] == 'FAILURE':
                        db.failed_builds.update_one(
                            {"pipeline_name": pipeline_name, "build_number": build['number']},
                            {"$set": build_data},
                            upsert=True
                        )
                    else:
                        # Remove from failed_builds if resolved
                        db.failed_builds.delete_one({"pipeline_name": pipeline_name, "build_number": build['number']})
                    # Only send email if this is a new build (not already in DB)
                    existing = db_manager.builds_collection.find_one({"pipeline_name": pipeline_name, "build_number": build['number']})
                    if not existing:
                        if build_data['status'] == 'SUCCESS':
                            send_success_email_to_recipient(build_data)
                        elif build_data['status'] == 'FAILURE':
                            send_failure_email_to_recipient(build_data)
                except Exception as build_err:
                    logger.error(f"Error processing build {build.get('number')} in pipeline {pipeline_name}", error=str(build_err))
        PIPELINE_GAUGE.set(len(pipelines))
        logger.info(f"Pipeline data collection completed. Found {len(pipelines)} pipelines")
    except Exception as e:
        logger.error("Pipeline data collection failed", error=str(e))
@app.route('/api/failed-builds', methods=['GET'])
def get_failed_builds():
    """Get unresolved failed builds"""
    try:
        failed_builds = list(db.failed_builds.find({}, {"_id": 0}))
        return jsonify(failed_builds)
    except Exception as e:
        logger.error(f"Failed to get failed builds", error=str(e))
        return jsonify({"error": str(e)}), 500
    """Collect data from Jenkins and update database"""
    try:
        logger.info("Starting pipeline data collection")
        pipelines = jenkins_monitor.get_pipelines()
        for pipeline in pipelines:
            pipeline_name = pipeline['name']
            pipeline_info = jenkins_monitor.get_pipeline_info(pipeline_name)
            if pipeline_info:
                db_manager.save_pipeline({
                    "name": pipeline_name,
                    "url": pipeline['url'],
                    "color": pipeline['color'],
                    "last_updated": datetime.now(),
                    "info": pipeline_info
                })
            builds = jenkins_monitor.get_latest_builds(pipeline_name, limit=100)  # Fetch up to 100 recent builds per pipeline
            for build in builds:
                try:
                    user = build.get('causes', [{}])[0].get('userName', '').strip()
                    if not user:
                        user = 'admin'
                    # Debug: Print build number, status, and result
                    logger.info(f"Processing build: pipeline={pipeline_name}, build_number={build.get('number')}, result={build.get('result')}, status={build.get('result', 'UNKNOWN')}")
                    build_data = {
                        "pipeline_name": str(pipeline_name),
                        "build_number": build.get('number'),
                        "url": build.get('url'),
                        "timestamp": datetime.fromtimestamp(build.get('timestamp', 0) / 1000),
                        "status": build.get('result', 'UNKNOWN'),
                        "duration": build.get('duration', 0) / 1000,
                        "estimated_duration": build.get('estimatedDuration', 0) / 1000,
                        "executor": build.get('executor', {}),
                        "last_updated": datetime.now(),
                        "user": user
                    }
                    db_manager.save_build(build_data)
                    BUILD_COUNTER.labels(status=build_data['status']).inc()
                    if build_data['duration'] > 0:
                        BUILD_DURATION.observe(build_data['duration'])
                    # Only send email if this is a new build (not already in DB)
                    existing = db_manager.builds_collection.find_one({"pipeline_name": pipeline_name, "build_number": build['number']})
                    if not existing:
                        if build_data['status'] == 'SUCCESS':
                            send_success_email_to_recipient(build_data)
                        elif build_data['status'] == 'FAILURE':
                            send_failure_email_to_recipient(build_data)
                except Exception as build_err:
                    logger.error(f"Error processing build {build.get('number')} in pipeline {pipeline_name}", error=str(build_err))
        PIPELINE_GAUGE.set(len(pipelines))
        logger.info(f"Pipeline data collection completed. Found {len(pipelines)} pipelines")
        
    except Exception as e:
        logger.error("Pipeline data collection failed", error=str(e))

def start_background_tasks():
    """Start background tasks for data collection every 30 seconds"""
    def run_scheduler():
        schedule.every(30).seconds.do(collect_pipeline_data)
        while True:
            schedule.run_pending()
            time.sleep(1)
    collect_pipeline_data()
    scheduler_thread = threading.Thread(target=run_scheduler, daemon=True)
    scheduler_thread.start()

def ensure_background_started():
    """Ensure background tasks started once (works under Gunicorn)."""
    global _bg_started
    if not _bg_started:
        try:
            start_background_tasks()
        except Exception as e:
            logger.error("Failed to start background tasks", error=str(e))
        _bg_started = True

    # No Flask hooks used; caller should invoke this during module import or app start

# API Routes
@app.route('/health')
def health_check():
    """Health check endpoint"""
    try:
        # Check MongoDB connection (hard requirement)
        client.admin.command('ping')

        # Check Jenkins connection (soft requirement)
        jenkins_status = "unknown"
        try:
            jenkins_response = jenkins_monitor.session.get(f"{JENKINS_URL}/api/json", timeout=3)
            jenkins_status = "connected" if jenkins_response.status_code == 200 else "disconnected"
        except Exception:
            jenkins_status = "disconnected"

        # Fetch job names from MongoDB pipelines collection
        job_names = []
        try:
            job_names = [p["name"] for p in db.pipelines.find({}, {"name": 1, "_id": 0})]
        except Exception as e:
            logger.error("Failed to fetch job names for health endpoint", error=str(e))

        return jsonify({
            "status": "healthy",
            "timestamp": datetime.now().isoformat(),
            "services": {
                "mongodb": "connected",
                "jenkins": jenkins_status
            },
            "jenkins_jobs": job_names
        }), 200
    except Exception as e:
        logger.error("Health check failed", error=str(e))
        return jsonify({
            "status": "unhealthy",
            "timestamp": datetime.now().isoformat(),
            "error": str(e)
        }), 500

@app.route('/api/pipelines')
def get_pipelines():
    """Get all pipelines"""
    try:
        pipelines = list(db.pipelines.find({}, {"_id": 0}))
        return jsonify(pipelines)
    except Exception as e:
        logger.error("Failed to get pipelines", error=str(e))
        return jsonify({"error": str(e)}), 500

@app.route('/api/pipelines/<pipeline_name>')
def get_pipeline(pipeline_name):
    """Get a single pipeline by name"""
    try:
        pipeline = db.pipelines.find_one({"name": pipeline_name}, {"_id": 0})
        if not pipeline:
            return jsonify({"error": "Pipeline not found"}), 404
        return jsonify(pipeline)
    except Exception as e:
        logger.error(f"Failed to get pipeline {pipeline_name}", error=str(e))
        return jsonify({"error": str(e)}), 500
@app.route('/api/pipelines/<pipeline_name>/builds')
def get_pipeline_builds(pipeline_name):
    """Get builds for a specific pipeline"""
    try:
        limit = int(request.args.get('limit', 50))  # Default to 50 builds
        builds = list(db.builds.find(
            {"pipeline_name": pipeline_name}, 
            {"_id": 0, "duration": 1, "build_number": 1, "timestamp": 1, "user": 1, "status": 1}
        ).sort("build_number", -1).limit(limit))
        # Ensure pipeline_name is present in every build object
        for b in builds:
            b["pipeline_name"] = pipeline_name
        return jsonify(builds)
    except Exception as e:
        logger.error(f"Failed to get builds for {pipeline_name}", error=str(e))
        return jsonify({"error": str(e)}), 500

@app.route('/api/pipelines/<pipeline_name>/metrics')
def get_pipeline_metrics(pipeline_name):
    """Get metrics for a specific pipeline"""
    try:
        days = int(request.args.get('days', 30))
        metrics = db_manager.get_pipeline_metrics(pipeline_name, days)
        return jsonify(metrics)
    except Exception as e:
        logger.error(f"Failed to get metrics for {pipeline_name}", error=str(e))
        return jsonify({"error": str(e)}), 500

@app.route('/api/metrics/overall')
def get_overall_metrics():
    """Get overall metrics across all pipelines"""
    try:
        days = int(request.args.get('days', 30))
        metrics = db_manager.get_overall_metrics(days)
        return jsonify(metrics)
    except Exception as e:
        logger.error("Failed to get overall metrics", error=str(e))
        return jsonify({"error": str(e)}), 500

@app.route('/api/advice')
def get_advice():
    """Get improvement advice and recent failures for a pipeline or overall"""
    try:
        pipeline = request.args.get('pipeline')
        days = int(request.args.get('days', 30))
        if pipeline:
            metrics = db_manager.get_pipeline_metrics(pipeline, days)
        else:
            metrics = db_manager.get_overall_metrics(days)
        recent_failures = db_manager.get_recent_failures(pipeline, limit=10)
        advice = generate_advice(metrics or {}, recent_failures)
        resources = generate_resources(recent_failures, pipeline)
        return jsonify({
            "metrics": metrics,
            "recent_failures": recent_failures,
            "advice": advice,
            "resources": resources
        })
    except Exception as e:
        logger.error("Failed to generate advice", error=str(e))
        return jsonify({"error": str(e)}), 500

@app.route('/api/email/advice', methods=['POST'])
def email_advice():
    """Send advice via email to provided recipients"""
    try:
        body = request.get_json(force=True) or {}
        recipients = body.get('recipients', [])
        pipeline = body.get('pipeline')
        days = int(body.get('days', 30))
        if not recipients:
            return jsonify({"error": "recipients required"}), 400
        if pipeline:
            metrics = db_manager.get_pipeline_metrics(pipeline, days)
        else:
            metrics = db_manager.get_overall_metrics(days)
        recent_failures = db_manager.get_recent_failures(pipeline, limit=10)
        advice = generate_advice(metrics or {}, recent_failures)

        html = f"""
        <h3>CI/CD Health Advice {f'for {pipeline}' if pipeline else ''}</h3>
        <p><strong>Success rate:</strong> {metrics.get('success_rate',0):.1f}%</p>
        <p><strong>Average build time:</strong> {metrics.get('avg_duration',0):.1f}s</p>
        <h4>Recommended Steps</h4>
        <ul>{''.join(f'<li>{a}</li>' for a in advice)}</ul>
        <h4>Recent Failures</h4>
        <ul>{''.join(f"<li>{f.get('pipeline_name')} #{f.get('build_number')} - {f.get('status')}</li>" for f in recent_failures)}</ul>
        """

        if not SMTP_CONFIG['username'] or not SMTP_CONFIG['password']:
            return jsonify({"error": "SMTP not configured"}), 400

        msg = MIMEText(html, 'html')
        msg['Subject'] = f"CI/CD Advice {f'for {pipeline}' if pipeline else ''}"
        msg['From'] = SMTP_CONFIG['username']
        msg['To'] = ', '.join(recipients)

        with smtplib.SMTP(SMTP_CONFIG['host'], SMTP_CONFIG['port']) as server:
            server.starttls()
            server.login(SMTP_CONFIG['username'], SMTP_CONFIG['password'])
            server.sendmail(SMTP_CONFIG['username'], recipients, msg.as_string())

        return jsonify({"message": "Email sent", "recipients": recipients})
    except Exception as e:
        logger.error("Failed to send advice email", error=str(e))
        return jsonify({"error": str(e)}), 500
@app.route('/metrics')
def prometheus_metrics():
    """Prometheus metrics endpoint"""
    return generate_latest()

@app.route('/api/trigger-collection')
def trigger_collection():
    """Manually trigger data collection and send email for only the most recent build per job."""
    try:
        manual = request.args.get('manual', '0') == '1'
        pipelines = jenkins_monitor.get_pipelines()
        for pipeline in pipelines:
            pipeline_name = pipeline['name']
            # Get the latest build from DB and Jenkins
            latest_db_build = db.builds.find_one({"pipeline_name": pipeline_name}, sort=[("build_number", -1)])
            latest_jenkins_builds = jenkins_monitor.get_latest_builds(pipeline_name, limit=1)
            for build in latest_jenkins_builds:
                build_number = build['number']
                # Only notify if Jenkins build is newer than DB build
                if not latest_db_build or build_number > latest_db_build.get('build_number', 0):
                    build_data = {
                        "pipeline_name": pipeline_name,
                        "build_number": build_number,
                        "url": build['url'],
                        "timestamp": datetime.fromtimestamp(build['timestamp'] / 1000),
                        "status": build.get('result', 'UNKNOWN'),
                        "duration": build.get('duration', 0) / 1000,
                        "estimated_duration": build.get('estimatedDuration', 0) / 1000,
                        "executor": build.get('executor', {}),
                        "last_updated": datetime.now(),
                        "user": build.get('causes', [{}])[0].get('userName', 'Unknown'),
                        "result": build.get('result', 'UNKNOWN')
                    }
                    if build_data['status'] == 'SUCCESS':
                        send_success_email_to_recipient(build_data)
                    elif build_data['status'] == 'FAILURE':
                        send_failure_email_to_recipient(build_data)
        collect_pipeline_data()
        return jsonify({"message": "Data collection and notifications triggered successfully"})
    except Exception as e:
        logger.error("Manual data collection failed", error=str(e))
        return jsonify({"error": str(e)}), 500

# WebSocket events
@socketio.on('connect')
def handle_connect():
    """Handle client connection"""
    logger.info("Client connected to WebSocket")
    emit('connected', {'data': 'Connected to CI/CD Dashboard'})

@socketio.on('disconnect')
def handle_disconnect():
    """Handle client disconnection"""
    logger.info("Client disconnected from WebSocket")

@socketio.on('subscribe_pipeline')
def handle_pipeline_subscription(data):
    """Handle pipeline subscription for real-time updates"""
    pipeline_name = data.get('pipeline_name')
    logger.info(f"Client subscribed to pipeline: {pipeline_name}")

# Error handlers
@app.errorhandler(404)

# Jenkins Node Health API
@app.route('/api/jenkins-node-health')
def jenkins_node_health():
    """Return Jenkins node health status, number of jobs, port, and connection status."""
    try:
        # Check Jenkins connection
        try:
            response = jenkins_monitor.session.get(f"{JENKINS_URL}/api/json", timeout=3)
            status = "up" if response.status_code == 200 else "down"
            data = response.json() if response.status_code == 200 else {}
        except Exception:
            status = "down"
            data = {}

        # Number of jobs
        num_jobs = len(data.get('jobs', [])) if data else 0

        # Extract Jenkins port from URL
        from urllib.parse import urlparse
        parsed_url = urlparse(JENKINS_URL)
        port = parsed_url.port if parsed_url.port else (443 if parsed_url.scheme == 'https' else 80)

        job_names = [job.get('name') for job in data.get('jobs', [])] if data else []
        return jsonify({
            "jenkins_url": JENKINS_URL,
            "port": port,
            "connection_status": status,
            "num_jobs": num_jobs,
            "jenkins_jobs": job_names
        })
    except Exception as e:
        logger.error("Failed to get Jenkins node health", error=str(e))
        return jsonify({"error": str(e)}), 500

@app.errorhandler(404)
def not_found(error):
    return jsonify({"error": "Resource not found"}), 404

@app.errorhandler(500)
def internal_error(error):
    return jsonify({"error": "Internal server error"}), 500

def send_success_email_to_recipient(build_data):
    """Send email for successful build to kumarmanglammishra@gmail.com."""
    try:
        recipients = ["kumarmanglammishra@gmail.com"]
        subject = f"Build Success: {build_data['pipeline_name']} #{build_data['build_number']}"
        triggered_by = build_data.get('user', '').strip() or 'admin'
        body = (
            f"Jenkins Job: {build_data['pipeline_name']}\n"
            f"Build Number: {build_data['build_number']}\n"
            f"Status: SUCCESS\n"
            f"Time: {build_data['timestamp']}\n"
            f"Triggered By: {triggered_by}\n"
            f"Duration: {build_data.get('duration', 0):.1f}s\n"
            "Message: Build completed successfully."
        )
        send_email(recipients, subject, body)
    except Exception as e:
        logger.error(f"Failed to send success email", error=str(e))

def send_failure_email_to_recipient(build_data):
    """Send email for failed build to kumarmanglammishra@gmail.com."""
    try:
        recipients = ["kumarmanglammishra@gmail.com"]
        subject = f"Build Failure: {build_data['pipeline_name']} #{build_data['build_number']}"
        metrics = db_manager.get_pipeline_metrics(build_data['pipeline_name'], days=30)
        recent_failures = db_manager.get_recent_failures(build_data['pipeline_name'], limit=3)
        advice = generate_advice(metrics, recent_failures)
        advice_str = "\n- ".join(advice)
        triggered_by = build_data.get('user', '').strip() or 'admin'
        body = (
            f"Jenkins Job: {build_data['pipeline_name']}\n"
            f"Build Number: {build_data['build_number']}\n"
            f"Status: FAILURE\n"
            f"Time: {build_data['timestamp']}\n"
            f"Triggered By: {triggered_by}\n"
            f"Duration: {build_data.get('duration', 0):.1f}s\n"
            f"URL: {build_data.get('url', '')}\n"
            f"Reason: {build_data.get('result', 'Unknown')}\n"
            f"Recommendations:\n- {advice_str}\n"
            f"Build Stats:\nTotal: {metrics.get('total', 0)}\nSuccess: {metrics.get('success', 0)}\nFailure: {metrics.get('failure', 0)}\nSuccess Rate: {metrics.get('success_rate', 0):.1f}%\nAvg Duration: {metrics.get('avg_duration', 0):.1f}s"
        )
        send_email(recipients, subject, body)
    except Exception as e:
        logger.error(f"Failed to send failure email", error=str(e))

def send_email(recipients, subject, body):
    """Send email utility."""
    try:
        # Filter out any invalid/empty recipients
        valid_recipients = [r for r in recipients if r and '@' in r]
        if not valid_recipients:
            logger.error(f"No valid email recipients provided: {recipients}")
            return
        msg = MIMEText(body)
        msg['Subject'] = subject
        msg['From'] = SMTP_CONFIG['username']
        msg['To'] = ', '.join(valid_recipients)
        with smtplib.SMTP(SMTP_CONFIG['host'], SMTP_CONFIG['port']) as server:
            server.starttls()
            server.login(SMTP_CONFIG['username'], SMTP_CONFIG['password'])
            server.sendmail(SMTP_CONFIG['username'], valid_recipients, msg.as_string())
        logger.info(f"Email sent to {valid_recipients} for {subject}")
    except Exception as e:
        logger.error(f"Failed to send email", error=str(e))

if __name__ == '__main__':
    ensure_background_started()
    socketio.run(app, host='0.0.0.0', port=5000, debug=False)
