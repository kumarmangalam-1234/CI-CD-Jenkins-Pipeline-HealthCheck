# Tech Design Document

## High-Level Architecture

```
+-------------------+        +-------------------+        +-------------------+
|   Frontend (UI)   | <----> |   Backend (API)   | <----> |    MongoDB (DB)   |
| Node.js + Express |        | Python Flask      |        | Pipelines, Builds |
| EJS, Chart.js     |        | Socket.IO, REST   |        | Metrics, Alerts   |
+-------------------+        +-------------------+        +-------------------+
        |                        |                        |
        |                        |                        |
        v                        v                        v
+-------------------+        +-------------------+        +-------------------+
|   Jenkins Server  |        |   Redis (Cache)   |        |   Nginx (Proxy)   |
+-------------------+        +-------------------+        +-------------------+
```
- **Frontend**: Provides dashboard UI, charts, and interacts with backend via REST and WebSocket.
- **Backend**: Integrates with Jenkins, manages DB, exposes REST API, WebSocket, Prometheus metrics, and alerting.
- **Database**: MongoDB stores pipelines, builds, metrics, alerts, health checks.
- **Infrastructure**: Docker Compose orchestrates all services; Redis for caching; Nginx for proxy/SSL.

## API Structure

### Main Routes
- `GET /health` — Health check endpoint
  - **Response:** `{ status: "healthy", service: "backend", timestamp: "..." }`
- `GET /api/pipelines` — List all pipelines
  - **Response:** `[ { name, url, color, last_updated, info } ]`
- `GET /api/pipelines/:name` — Get pipeline details
  - **Response:** `{ name, url, color, last_updated, info }`
- `GET /api/pipelines/:name/builds` — Get builds for a pipeline
  - **Response:** `[ { build_number, status, duration, timestamp, url } ]`
- `GET /api/pipelines/:name/metrics` — Get metrics for a pipeline
  - **Response:** `{ total, success, failure, success_rate, avg_duration }`
- `GET /api/metrics/overall` — Get overall metrics
  - **Response:** `{ total, success, failure, success_rate, avg_duration }`
- `POST /api/builds` — Add build data (used by simulator/demo)
- `POST /api/pipelines` — Add/update pipeline data (used by simulator/demo)

### Sample Response
```json
{
  "name": "frontend-build",
  "url": "https://jenkins.example.com/job/frontend-build",
  "color": "blue",
  "last_updated": "2025-08-22T10:00:00Z",
  "info": {
    "description": "Frontend application build pipeline",
    "healthReport": [{ "score": 100, "description": "Build stability: 100%" }]
  }
}
```

## Database Schema

### Collections
- **pipelines**
  - `name` (string, unique)
  - `url` (string)
  - `color` (string)
  - `last_updated` (datetime)
  - `info` (object)
- **builds**
  - `pipeline_name` (string)
  - `build_number` (int)
  - `url` (string)
  - `timestamp` (datetime)
  - `status` (string)
  - `duration` (int)
  - `estimated_duration` (int)
  - `executor` (object)
  - `last_updated` (datetime)
- **metrics**
  - `pipeline_name` (string)
  - `date` (date)
  - `total_builds` (int)
  - `successful_builds` (int)
  - `failed_builds` (int)
  - `success_rate` (float)
  - `avg_duration` (float)
  - `total_duration` (int)
- **alerts**
  - `pipeline_name` (string)
  - `build_number` (int)
  - `timestamp` (datetime)
  - `type` (string)
- **health_checks**
  - `timestamp` (datetime)
  - `service` (string)

## UI Layout (Explanation)

- **Dashboard Page**
  - Navigation bar with status indicator and refresh button
  - Overview cards: Total Pipelines, Success Rate, Avg Build Time, Total Builds
  - Charts: Status distribution (doughnut), Build duration trend (line)
  - Table: List of pipelines with status, last build, build time, success rate, actions

- **Pipeline Detail Page**
  - Success Rate, Avg Build Time, Total Builds (cards)
  - Recent Builds table: build number, status, duration, timestamp, link to Jenkins
  - Navigation back to dashboard

- **Error Handling**
  - Alerts for errors and failed data loads
  - 404 and 500 error pages

---

This document provides a technical design overview for the CI/CD Pipeline Health Dashboard, covering architecture, API, database schema, and UI layout.
