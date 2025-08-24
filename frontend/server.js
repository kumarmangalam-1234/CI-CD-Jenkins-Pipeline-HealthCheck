const express = require('express');
const path = require('path');
const axios = require('axios');

const app = express();
const PORT = process.env.PORT || 3000;
// BACKEND_URL is used for server-to-server calls inside the container network
// PUBLIC_BACKEND_URL is what the browser should call (host-exposed URL)
const BACKEND_URL = process.env.BACKEND_URL || 'http://localhost:5000';
const PUBLIC_BACKEND_URL = process.env.PUBLIC_BACKEND_URL || BACKEND_URL;

// View engine setup
app.set('view engine', 'ejs');
app.set('views', path.join(__dirname, 'views'));

// Middleware
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(express.static(path.join(__dirname, 'public')));

// Health check endpoint
app.get('/health', (req, res) => {
    res.status(200).json({
        status: 'healthy',
        service: 'frontend',
        timestamp: new Date().toISOString()
    });
});

// Main dashboard route
app.get('/', async (req, res) => {
    try {
        // Fetch initial data from backend
        const [pipelinesResponse, overallMetricsResponse] = await Promise.allSettled([
            axios.get(`${BACKEND_URL}/api/pipelines`),
            axios.get(`${BACKEND_URL}/api/metrics/overall`)
        ]);

        const pipelines = pipelinesResponse.status === 'fulfilled' ? pipelinesResponse.value.data : [];
        const overallMetrics = overallMetricsResponse.status === 'fulfilled' ? overallMetricsResponse.value.data : {};

        res.render('dashboard', {
            pipelines,
            overallMetrics,
            backendUrl: PUBLIC_BACKEND_URL
        });
    } catch (error) {
        console.error('Error fetching dashboard data:', error);
        res.render('dashboard', {
            pipelines: [],
            overallMetrics: {},
            backendUrl: PUBLIC_BACKEND_URL,
            error: 'Failed to load dashboard data'
        });
    }
});

// Pipeline detail route
app.get('/pipeline/:name', async (req, res) => {
    try {
        const pipelineName = req.params.name;
        
        const [pipelineResponse, buildsResponse, metricsResponse] = await Promise.allSettled([
            axios.get(`${BACKEND_URL}/api/pipelines/${pipelineName}`),
            axios.get(`${BACKEND_URL}/api/pipelines/${pipelineName}/builds`),
            axios.get(`${BACKEND_URL}/api/pipelines/${pipelineName}/metrics`)
        ]);

        const pipeline = pipelineResponse.status === 'fulfilled' ? pipelineResponse.value.data : {};
        const builds = buildsResponse.status === 'fulfilled' ? buildsResponse.value.data : [];
        const metrics = metricsResponse.status === 'fulfilled' ? metricsResponse.value.data : {};

        res.render('pipeline-detail', {
            pipeline,
            builds,
            metrics,
            pipelineName,
            backendUrl: BACKEND_URL
        });
    } catch (error) {
        console.error('Error fetching pipeline data:', error);
        res.status(500).render('error', {
            message: 'Failed to load pipeline data',
            error: error.message
        });
    }
});

// API proxy routes for CORS handling
app.get('/api/*', async (req, res) => {
    try {
        const apiPath = req.params[0];
        const response = await axios.get(`${BACKEND_URL}/api/${apiPath}`, {
            params: req.query,
            headers: {
                'User-Agent': 'CI-CD-Dashboard-Frontend/1.0'
            }
        });
        res.json(response.data);
    } catch (error) {
        console.error('API proxy error:', error);
        res.status(error.response?.status || 500).json({
            error: 'Failed to fetch data from backend',
            details: error.message
        });
    }
});

// Error handling middleware
app.use((req, res, next) => {
    res.status(404).render('error', {
        message: 'Page not found',
        error: 'The requested page could not be found'
    });
});

app.use((error, req, res, next) => {
    console.error('Unhandled error:', error);
    res.status(500).render('error', {
        message: 'Internal server error',
        error: process.env.NODE_ENV === 'development' ? error.message : 'Something went wrong'
    });
});

// Start server
app.listen(PORT, () => {
    console.log(`🚀 Frontend server running on port ${PORT}`);
    console.log(`📊 Dashboard available at http://localhost:${PORT}`);
    console.log(`🔗 Backend URL: ${BACKEND_URL}`);
});

module.exports = app;
