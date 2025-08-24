
# CI/CD Health Dashboard 

1.Hi Cursor, consider yourself as a Senior Software Engineer I would like you to Architect a scaleable CI/CD Pipeline Health Dashboard web application to monitor executions from tools like Jenkins. This will include the following features:-
a. Collect data on pipeline executions (success/failure, build time, status)
b. Show real-time metrics:
o Success/Failure rate
o Average build time
o Last build status
c. Send alerts (via Slack or Email) on pipeline failures.
d. Provide a simple frontend UI to:
o Visualize pipeline metrics
o Display logs/status of latest builds
I would like you simulate how modern engineering teams monitor the health of their CI/CD systems using automation, observability, and actionable alerting works as per the industry standards. Please build frontend using node, backend on pyhton and database as mysql/mongodb which ever you choose.
2. Design RESTful API endpoints for pipelines, builds, metrics, and health checks, following OpenAPI/Swagger standards and secure CORS policies.
3. Implement user attribution logic to reliably extract the Jenkins user who triggered each build, with a fallback to a default value for auditability.
4. Guarantee all build records include validated duration, timestamp, status, and user fields, enforcing schema integrity at the database layer.
5. Develop a responsive frontend dashboard using modern frameworks (e.g., React or Vue preferred, fallback to vanilla JS/Chart.js), with real-time data updates and intuitive UX.
6. Integrate auto-refresh and manual refresh controls, ensuring the dashboard reflects the latest build and pipeline states without user intervention.
7. Visualize build duration trends using time-series charts, plotting the most recent 50 builds per pipeline, with clear axis labels and tooltips.
8. Display triggering user, build status, and duration in both the dashboard and notification emails, supporting traceability and compliance.
9. Calculate and render success/failure percentages for each pipeline, using color-coded progress bars and accessible labels.
10. Assess pipeline health status ("Healthy" or "Unhealthy") based on configurable thresholds (e.g., failure rate > 20%), and surface this in the UI and API.
11. Implement transactional email notifications for new builds, including actionable links, build metadata, and remediation advice for failures.
12. Provide a self-service advice tab in the dashboard, offering automated recommendations and links to relevant documentation for pipeline improvement.
13. Ensure all API responses are paginated, filterable, and include all necessary build metadata for frontend consumption.
14. Enforce frontend validation and error handling for all data visualizations, preventing UI breakage on missing or malformed data.
15. Conduct end-to-end testing and validation of the dashboard, APIs, and notification flows, ensuring reliability, security, and maintainability.


