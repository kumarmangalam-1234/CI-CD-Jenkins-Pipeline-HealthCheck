/**
 * CI/CD Pipeline Health Dashboard JavaScript
 * Handles real-time updates, charts, and data management
 */

class DashboardManager {
    applyFilters() {
        const name = document.getElementById('filter-name').value.trim().toLowerCase();
        const user = document.getElementById('filter-user').value.trim().toLowerCase();
        const status = document.getElementById('filter-status').value;
        const minBuildTime = parseFloat(document.getElementById('filter-build-time').value);

        const rows = document.querySelectorAll('#pipelines-tbody tr');
        rows.forEach(row => {
            let show = true;
            // Filter by name
            if (name) {
                const jobName = row.querySelector('td:first-child strong').textContent.toLowerCase();
                if (!jobName.includes(name)) show = false;
            }
            // Filter by user
            if (user) {
                const userCell = row.querySelector('td:nth-child(3) small.text-muted');
                if (!userCell || !userCell.textContent.toLowerCase().includes(user)) show = false;
            }
            // Filter by status
            if (status) {
                const statusCell = row.querySelector('td:nth-child(2) .badge');
                if (!statusCell || statusCell.textContent.toUpperCase() !== status) show = false;
            }
            // Filter by build time
            if (!isNaN(minBuildTime) && minBuildTime > 0) {
                const buildTimeCell = row.querySelector('td:nth-child(4)');
                const timeText = buildTimeCell ? buildTimeCell.textContent : '';
                const seconds = this.parseDurationToSeconds(timeText);
                if (seconds < minBuildTime) show = false;
            }
            row.style.display = show ? '' : 'none';
        });
    }

    clearFilters() {
        document.getElementById('filter-name').value = '';
        document.getElementById('filter-user').value = '';
        document.getElementById('filter-status').value = '';
        document.getElementById('filter-build-time').value = '';
        this.applyFilters();
    }

    parseDurationToSeconds(durationStr) {
        // Converts "Xm Ys" or "Ys" to seconds
        if (!durationStr) return 0;
        const match = durationStr.match(/(?:(\d+)m)?\s*(\d+(?:\.\d+)?)s/);
        if (!match) return 0;
        const minutes = parseInt(match[1] || '0', 10);
        const seconds = parseFloat(match[2] || '0');
        return minutes * 60 + seconds;
    }
    failedBuilds = [];
    async fetchFailedBuilds() {
        try {
            const res = await fetch(`${this.backendUrl}/api/failed-builds`);
            if (res.ok) {
                this.failedBuilds = await res.json();
                this.updateFailedBuildsBadge();
            }
        } catch (e) {
            console.error('Failed to fetch failed builds:', e);
        }
    }

    updateFailedBuildsBadge() {
        const count = this.failedBuilds.length;
        const badge = document.getElementById('failed-builds-count');
        if (badge) {
            badge.textContent = count;
            badge.style.display = count > 0 ? 'inline-block' : 'none';
        }
    }

    showFailedBuilds() {
        if (!this.failedBuilds.length) return;
        let html = '<div class="card shadow" style="min-width:300px;max-width:400px;z-index:9999;position:absolute;top:60px;right:30px;">';
        html += '<div class="card-header bg-danger text-white"><i class="fas fa-bell"></i> Failed Builds</div>';
        html += '<ul class="list-group list-group-flush">';
        this.failedBuilds.forEach(b => {
            const url = b.pipeline_name && b.build_number ? `http://localhost:4000/job/${b.pipeline_name}/${b.build_number}/console` : 'http://localhost:4000/';
            html += `<li class="list-group-item d-flex justify-content-between align-items-center">
                <span><strong>${b.pipeline_name}</strong> #${b.build_number} <span class="badge bg-danger ms-2">${b.status}</span></span>
                <a href="${url}" target="_blank" class="btn btn-sm btn-outline-danger" onclick="window.dashboardManager.markFailedBuildViewed('${b.pipeline_name}', ${b.build_number})">View</a>
            </li>`;
        });
        html += '</ul></div>';
        let dropdown = document.getElementById('failed-builds-dropdown');
        if (!dropdown) {
            dropdown = document.createElement('div');
            dropdown.id = 'failed-builds-dropdown';
            document.body.appendChild(dropdown);
        }
        dropdown.innerHTML = html;
        dropdown.style.display = 'block';
        // Hide dropdown on click outside
        document.addEventListener('click', function handler(e) {
            if (!dropdown.contains(e.target) && e.target.id !== 'failed-builds-alert') {
                dropdown.style.display = 'none';
                document.removeEventListener('click', handler);
            }
        });
    }

    async markFailedBuildViewed(pipeline_name, build_number) {
        try {
            await fetch(`${this.backendUrl}/api/failed-builds/viewed`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ pipeline_name, build_number })
            });
            // Re-fetch failed builds from backend to ensure sync
            await this.fetchFailedBuilds();
            this.showFailedBuilds();
        } catch (e) {
            console.error('Failed to mark failed build as viewed:', e);
        }
    }
    constructor() {
        this.pipelines = [];
        this.overallMetrics = {};
        this.charts = {};
        this.socket = null;
        // backendUrl will be set by initializeDashboard
        this.backendUrl = '';
        this.currentFilter = 'all';
        this.refreshInterval = null;
        window.dashboardManager = this;
        this.init();
    }
    
    init() {
        this.setupEventListeners();
        this.setupWebSocket();
        // Auto-refresh every 30 seconds, but do not block UI
        this.startAutoRefresh();
    // Setup filter buttons
    document.getElementById('apply-filters').addEventListener('click', () => this.applyFilters());
    document.getElementById('clear-filters').addEventListener('click', () => this.clearFilters());
    }
    
    setupEventListeners() {
        // Setup refresh button
        document.addEventListener('click', (e) => {
            if (e.target.matches('[data-action="refresh"]')) {
                this.refreshData();
            }
        });
        
        // Setup filter buttons
        document.addEventListener('click', (e) => {
            if (e.target.matches('[data-filter]')) {
                const filter = e.target.dataset.filter;
                this.filterPipelines(filter);
            }
        });
    }
    
    setupWebSocket() {
        try {
            // Initialize Socket.IO connection to backend using correct URL
            // Note: If using Flask-SocketIO backend, use Socket.IO v3.x client for best compatibility
            this.socket = io(this.backendUrl, {
                transports: ['websocket', 'polling'],
                withCredentials: true
            });
            this.socket.on('connect', () => {
                this.updateConnectionStatus('Connected', 'success');
                console.log('Connected to backend via WebSocket');
            });
            this.socket.on('disconnect', () => {
                this.updateConnectionStatus('Disconnected', 'danger');
                console.log('Disconnected from backend');
            });
            this.socket.on('pipeline_update', (data) => {
                this.handlePipelineUpdate(data);
            });
            this.socket.on('build_update', (data) => {
                this.handleBuildUpdate(data);
            });
        } catch (error) {
            console.error('WebSocket setup failed:', error);
            this.updateConnectionStatus('WebSocket Error', 'warning');
        }
    }
    
    updateConnectionStatus(status, type) {
        const statusElement = document.getElementById('connection-status');
        const iconElement = statusElement.previousElementSibling;
        
        if (statusElement && iconElement) {
            statusElement.textContent = status;
            iconElement.className = `fas fa-circle text-${type} me-1`;
        }
    }
    
    startAutoRefresh() {
        if (this.refreshInterval) clearInterval(this.refreshInterval);
        this.refreshInterval = setInterval(() => {
            this.refreshData();
        }, 30000); // 30 seconds
    }
    
    async refreshData() {
    await this.fetchFailedBuilds();
        try {
            const isManual = !!window._manualRefresh;
            if (isManual) this.showLoading(true);
            // First, trigger backend data collection, pass manual flag
            await fetch(`${this.backendUrl}/api/trigger-collection?manual=${isManual ? '1' : '0'}`);
            // Fetch fresh data from backend
            const [pipelinesResponse, metricsResponse] = await Promise.all([
                fetch(`${this.backendUrl}/api/pipelines`),
                fetch(`${this.backendUrl}/api/metrics/overall`)
            ]);
            if (pipelinesResponse.ok && metricsResponse.ok) {
                const pipelines = await pipelinesResponse.json();
                const metrics = await metricsResponse.json();
                let newBuildDetected = false;
                for (let i = 0; i < pipelines.length; i++) {
                    const pipeline = pipelines[i];
                    // Fetch the latest 50 builds for each pipeline
                    const buildsRes = await fetch(`${this.backendUrl}/api/pipelines/${encodeURIComponent(pipeline.name)}/builds?limit=50`);
                    if (buildsRes.ok) {
                        pipeline.info = pipeline.info || {};
                        const newBuilds = await buildsRes.json();
                        // Compare with previous builds
                        const prevBuilds = (this.pipelines[i] && this.pipelines[i].info && this.pipelines[i].info.builds) || [];
                        if (newBuilds.length > 0 && (!prevBuilds.length || newBuilds[0].number !== prevBuilds[0].number)) {
                            newBuildDetected = true;
                            console.log(`[AutoRefresh] New build detected for pipeline: ${pipeline.name}, build number: ${newBuilds[0].number}`);
                        }
                        pipeline.info.builds = newBuilds;
                    }
                }
                // Always update dashboard every interval
                console.log(`[AutoRefresh] Dashboard updated. New build detected: ${newBuildDetected}, Manual: ${isManual}`);
                this.updateDashboard(pipelines, metrics);
            } else {
                throw new Error('Failed to fetch data');
            }
        } catch (error) {
            console.error('Error refreshing data:', error);
            this.showError('Failed to refresh data: ' + error.message);
        } finally {
            if (!!window._manualRefresh) this.showLoading(false);
            window._manualRefresh = false;
        }
    }
    
    updateDashboard(pipelines, metrics) {
        this.pipelines = pipelines;
        this.overallMetrics = metrics;
        
        this.updateOverviewCards();
        this.updateCharts();
        this.updatePipelinesTable();
    }
    
    updateOverviewCards() {
        // Update total pipelines
        const totalPipelines = this.pipelines.length;
        this.updateCard('total-pipelines', totalPipelines);
        
        // Update success rate
        const successRate = this.overallMetrics.success_rate || 0;
        this.updateCard('success-rate', `${successRate.toFixed(1)}%`);
        
        // Update average build time
        const avgBuildTime = this.overallMetrics.avg_duration || 0;
        this.updateCard('avg-build-time', this.formatDuration(avgBuildTime));
        
        // Update total builds
        const totalBuilds = this.overallMetrics.total || 0;
        this.updateCard('total-builds', totalBuilds);
    }
    
    updateCard(elementId, value) {
        const element = document.getElementById(elementId);
        if (element) {
            element.textContent = value;
        }
    }
    
    updateCharts() {
        this.updateStatusChart();
        this.updateDurationChart();
    }
    
    updateStatusChart() {
        const ctx = document.getElementById('statusChart');
        if (!ctx) return;
        
        // Destroy existing chart if it exists
        if (this.charts.statusChart) {
            this.charts.statusChart.destroy();
        }
        
        const statusCounts = this.calculateStatusCounts();
        
        this.charts.statusChart = new Chart(ctx, {
            type: 'doughnut',
            data: {
                labels: ['Success', 'Failure', 'In Progress', 'Unknown'],
                datasets: [{
                    data: [
                        statusCounts.success || 0,
                        statusCounts.failure || 0,
                        statusCounts.inProgress || 0,
                        statusCounts.unknown || 0
                    ],
                    backgroundColor: [
                        '#28a745',
                        '#dc3545',
                        '#ffc107',
                        '#6c757d'
                    ],
                    borderWidth: 2,
                    borderColor: '#fff'
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                plugins: {
                    legend: {
                        position: 'bottom'
                    },
                    tooltip: {
                        callbacks: {
                            label: function(context) {
                                const label = context.label || '';
                                const value = context.parsed || 0;
                                const total = context.dataset.data.reduce((a, b) => a + b, 0);
                                const percentage = ((value / total) * 100).toFixed(1);
                                return `${label}: ${value} (${percentage}%)`;
                            }
                        }
                    }
                }
            }
        });
    }
    
    updateDurationChart() {
        const ctx = document.getElementById('durationChart');
        if (!ctx) return;
        
        // Destroy existing chart if it exists
        if (this.charts.durationChart) {
            this.charts.durationChart.destroy();
        }
        
        const durationData = this.calculateDurationData();
        
        this.charts.durationChart = new Chart(ctx, {
            type: 'line',
            data: {
                labels: durationData.labels,
                datasets: [{
                    label: 'Build Duration (minutes)',
                    data: durationData.durations,
                    borderColor: '#007bff',
                    backgroundColor: 'rgba(0, 123, 255, 0.1)',
                    borderWidth: 2,
                    fill: true,
                    tension: 0.4
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                scales: {
                    y: {
                        beginAtZero: true,
                        title: {
                            display: true,
                            text: 'Duration (minutes)'
                        }
                    },
                    x: {
                        title: {
                            display: true,
                            text: 'Build Number'
                        }
                    }
                },
                plugins: {
                    legend: {
                        display: true,
                        position: 'top'
                    }
                }
            }
        });
    }
    
    calculateStatusCounts() {
        const counts = { success: 0, failure: 0, inProgress: 0, unknown: 0 };
        
        this.pipelines.forEach(pipeline => {
            const status = pipeline.color || 'unknown';
            if (status.includes('blue')) counts.success++;
            else if (status.includes('red')) counts.failure++;
            else if (status.includes('yellow')) counts.inProgress++;
            else counts.unknown++;
        });
        
        return counts;
    }
    
    calculateDurationData() {
        // Only plot the latest 50 builds for the first pipeline (or selected pipeline)
        let builds = [];
        if (this.pipelines.length > 0 && this.pipelines[0].info && this.pipelines[0].info.builds) {
            builds = this.pipelines[0].info.builds
                .filter(b => typeof b.duration === 'number' && b.duration > 0 && b.build_number)
                .slice(0, 50);
        }
        if (builds.length === 0) {
            return {
                labels: ['#101', '#102', '#103', '#104', '#105', '#106', '#107', '#108', '#109', '#110'],
                durations: ['2.5', '3.1', '2.8', '3.0', '2.7', '3.2', '2.9', '3.3', '2.6', '3.0']
            };
        }
        // Sort by build number ascending
        builds.sort((a, b) => a.build_number - b.build_number);
        return {
            labels: builds.map(b => `#${b.build_number}`),
            durations: builds.map(b => (b.duration / 60).toFixed(1))
        };
    }
    
    updatePipelinesTable() {
        const tbody = document.getElementById('pipelines-tbody');
        if (!tbody) return;
        
        tbody.innerHTML = '';
        
        this.pipelines.forEach(pipeline => {
            const row = this.createPipelineRow(pipeline);
            tbody.appendChild(row);
        });
    }
    
    createPipelineRow(pipeline) {
        const row = document.createElement('tr');
        const status = this.getPipelineStatus(pipeline);
        const lastBuild = this.getLastBuildInfo(pipeline);
        const buildTime = this.getBuildTime(pipeline);
        let triggeredBy = 'admin';
        if (lastBuild && lastBuild.user) {
            triggeredBy = lastBuild.user;
        }
        // Calculate success and failure percentage
        let successCount = 0, failureCount = 0;
        if (pipeline.info && pipeline.info.builds) {
            pipeline.info.builds.forEach(b => {
                if (b.status === 'SUCCESS') successCount++;
                if (b.status === 'FAILURE') failureCount++;
            });
        }
        const totalBuilds = successCount + failureCount;
        const successRate = totalBuilds > 0 ? (successCount / totalBuilds) * 100 : 0;
        const failureRate = totalBuilds > 0 ? (failureCount / totalBuilds) * 100 : 0;
        // Health status
        const healthStatus = failureRate < 20 ? 'Healthy' : 'Unhealthy';
        const healthColor = healthStatus === 'Healthy' ? 'success' : 'danger';
        row.innerHTML = `
            <td>
                <strong>${pipeline.name}</strong>
                <br>
                <small class="text-muted">${pipeline.url || ''}</small>
            </td>
            <td>
                <span class="badge bg-${status.color}">${status.text}</span>
                <br>
                <span class="badge bg-${healthColor} mt-1">${healthStatus}</span>
            </td>
            <td>
                ${lastBuild ? `#${lastBuild.number}` : 'N/A'}
                <br>
                <small class="text-muted">${lastBuild ? this.formatTimestamp(lastBuild.timestamp) : ''}</small>
            </td>
            <td>${buildTime}</td>
            <td>${triggeredBy}</td>
            <td>
                <div class="progress" style="height: 20px;">
                    <div class="progress-bar bg-success" style="width: ${successRate}%">
                        Success: ${successRate.toFixed(1)}%
                    </div>
                    <div class="progress-bar bg-danger" style="width: ${failureRate}%">
                        Failure: ${failureRate.toFixed(1)}%
                    </div>
                </div>
            </td>
            <td>
                <a href="/pipeline/${encodeURIComponent(pipeline.name)}" class="btn btn-sm btn-outline-primary">
                    <i class="fas fa-eye"></i> View
                </a>
                <button class="btn btn-sm btn-outline-secondary" onclick="refreshPipeline('${pipeline.name}')">
                    <i class="fas fa-sync-alt"></i>
                </button>
            </td>
        `;
        return row;
    }
    
    getPipelineStatus(pipeline) {
        const color = pipeline.color || '';
        
        if (color.includes('blue')) return { text: 'Success', color: 'success' };
        if (color.includes('red')) return { text: 'Failure', color: 'danger' };
        if (color.includes('yellow')) return { text: 'In Progress', color: 'warning' };
        if (color.includes('grey')) return { text: 'Disabled', color: 'secondary' };
        
        return { text: 'Unknown', color: 'secondary' };
    }
    
    getLastBuildInfo(pipeline) {
        if (pipeline.info && pipeline.info.builds && pipeline.info.builds.length > 0) {
            return pipeline.info.builds[0]; // First build is the latest
        }
        return null;
    }
    
    getBuildTime(pipeline) {
        const lastBuild = this.getLastBuildInfo(pipeline);
        if (lastBuild && lastBuild.duration) {
            return this.formatDuration(lastBuild.duration);
        }
        return 'N/A';
    }
    
    getSuccessRate(pipeline) {
        // This would need to be calculated from actual build data
        // For now, return a placeholder
        return Math.random() * 100;
    }
    
    formatDuration(seconds) {
        if (!seconds) return 'N/A';
        
        const minutes = Math.floor(seconds / 60);
        const remainingSeconds = seconds % 60;
        
        if (minutes > 0) {
            return `${minutes}m ${remainingSeconds.toFixed(0)}s`;
        }
        return `${remainingSeconds.toFixed(1)}s`;
    }
    
    formatTimestamp(timestamp) {
        if (!timestamp) return 'N/A';
        
        const date = new Date(timestamp);
        return moment(date).fromNow();
    }
    
    filterPipelines(filter) {
        this.currentFilter = filter;
        
        const rows = document.querySelectorAll('#pipelines-tbody tr');
        
        rows.forEach(row => {
            const statusCell = row.querySelector('td:nth-child(2) .badge');
            if (statusCell) {
                const status = statusCell.textContent.toLowerCase();
                
                let show = true;
                if (filter === 'success' && !status.includes('success')) show = false;
                if (filter === 'failure' && !status.includes('failure')) show = false;
                
                row.style.display = show ? '' : 'none';
            }
        });
        
        // Update active filter button
        document.querySelectorAll('[data-filter]').forEach(btn => {
            btn.classList.remove('active');
        });
        document.querySelector(`[data-filter="${filter}"]`)?.classList.add('active');
    }
    
    handlePipelineUpdate(data) {
        console.log('Pipeline update received:', data);
        // Update specific pipeline data
        this.refreshData();
    }
    
    handleBuildUpdate(data) {
        console.log('Build update received:', data);
        // Update specific build data
        this.refreshData();
    }
    
    showLoading(show) {
        const modal = document.getElementById('loadingModal');
        if (modal) {
            if (show) {
                new bootstrap.Modal(modal).show();
            } else {
                const modalInstance = bootstrap.Modal.getInstance(modal);
                if (modalInstance) {
                    modalInstance.hide();
                }
            }
        }
    }
    
    showError(message) {
        // Create and show error alert
        const alertDiv = document.createElement('div');
        alertDiv.className = 'alert alert-danger alert-dismissible fade show';
        alertDiv.innerHTML = `
            <i class="fas fa-exclamation-triangle me-2"></i>
            ${message}
            <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
        `;
        
        const container = document.querySelector('.container-fluid');
        if (container) {
            container.insertBefore(alertDiv, container.firstChild);
        }
        
        // Auto-remove after 5 seconds
        setTimeout(() => {
            if (alertDiv.parentNode) {
                alertDiv.remove();
            }
        }, 5000);
    }

    async loadAdvice(pipelineName) {
        try {
            const url = new URL(`${this.backendUrl}/api/advice`);
            if (pipelineName) url.searchParams.set('pipeline', pipelineName);
            const res = await fetch(url.toString());
            if (!res.ok) throw new Error('Failed to load advice');
            const data = await res.json();
            const adviceList = document.getElementById('advice-list');
            const failuresList = document.getElementById('failures-list');
            if (adviceList) adviceList.innerHTML = (data.advice || []).map(a => `<li>${a}</li>`).join('');
            if (failuresList) failuresList.innerHTML = (data.recent_failures || []).map(f => `<li>${f.pipeline_name} #${f.build_number} - ${f.status}</li>`).join('');

            // Render resource links
            let resourcesEl = document.getElementById('resources-list');
            if (!resourcesEl) {
                const adviceContainer = document.getElementById('advice-content');
                if (adviceContainer) {
                    const hdr = document.createElement('h6');
                    hdr.className = 'mt-3';
                    hdr.textContent = 'Helpful Resources';
                    adviceContainer.appendChild(hdr);
                    resourcesEl = document.createElement('ul');
                    resourcesEl.id = 'resources-list';
                    adviceContainer.appendChild(resourcesEl);
                }
            }
            if (resourcesEl) {
                resourcesEl.innerHTML = (data.resources || []).map(r => `<li><a href="${r.url}" target="_blank">${r.title}</a></li>`).join('');
            }
        } catch (e) {
            this.showError('Failed to load advice');
        }
    }

    async sendAdviceEmail(recipientsCsv, pipelineName) {
        try {
            const recipients = recipientsCsv.split(',').map(s => s.trim()).filter(Boolean);
            const res = await fetch(`${this.backendUrl}/api/email/advice`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ recipients, pipeline: pipelineName })
            });
            const status = document.getElementById('email-status');
            if (res.ok) {
                if (status) status.innerHTML = '<div class="alert alert-success">Email sent successfully.</div>';
            } else {
                const txt = await res.text();
                if (status) status.innerHTML = `<div class="alert alert-danger">Failed to send email: ${txt}</div>`;
            }
        } catch (e) {
            const status = document.getElementById('email-status');
            if (status) status.innerHTML = `<div class="alert alert-danger">Error: ${e.message}</div>`;
        }
    }
}

// Global functions for HTML onclick handlers
function refreshData() {
    window._manualRefresh = true;
    if (window.dashboardManager) {
        window.dashboardManager.refreshData();
    }
}

// Add a button to trigger backend data collection manually
document.addEventListener('DOMContentLoaded', () => {
    const nav = document.querySelector('.navbar-nav');
    if (nav) {
        const triggerBtn = document.createElement('button');
        triggerBtn.className = 'btn btn-outline-warning btn-sm ms-2';
        triggerBtn.innerHTML = '<i class="fas fa-bolt"></i> Reload from Jenkins';
        triggerBtn.onclick = async () => {
            if (window.dashboardManager) {
                window.dashboardManager.showLoading(true);
                try {
                    const res = await fetch(`${window.dashboardManager.backendUrl}/api/trigger-collection`);
                    if (res.ok) {
                        window.dashboardManager.showError('Backend data collection triggered. Please refresh after a few seconds.');
                    } else {
                        window.dashboardManager.showError('Failed to trigger backend data collection.');
                    }
                } catch (e) {
                    window.dashboardManager.showError('Error triggering backend data collection.');
                } finally {
                    window.dashboardManager.showLoading(false);
                }
            }
        };
        nav.appendChild(triggerBtn);
    }
});

function filterPipelines(filter) {
    if (window.dashboardManager) {
        window.dashboardManager.filterPipelines(filter);
    }
}

function refreshPipeline(pipelineName) {
    if (window.dashboardManager) {
        window.dashboardManager.refreshData();
    }
}

// Initialize dashboard when DOM is loaded
function initializeDashboard(data) {
    window.dashboardManager = new DashboardManager();
    window.dashboardManager.backendUrl = data.backendUrl;
    window.dashboardManager.updateDashboard(data.pipelines, data.overallMetrics);
}

// Tab helpers bound from HTML buttons
async function loadAdvice() {
    const val = document.getElementById('advice-pipeline')?.value || '';
    if (window.dashboardManager) {
        await window.dashboardManager.loadAdvice(val);
    }
}

async function sendAdviceEmail() {
    const recipients = document.getElementById('email-recipients')?.value || '';
    const pipeline = document.getElementById('email-pipeline')?.value || '';
    if (window.dashboardManager) {
        await window.dashboardManager.sendAdviceEmail(recipients, pipeline);
    }
}

// Export for use in other modules
if (typeof module !== 'undefined' && module.exports) {
    module.exports = DashboardManager;
}
