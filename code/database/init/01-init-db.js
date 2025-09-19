// MongoDB initialization script for CI/CD Dashboard
// This script runs when the MongoDB container starts

print('🚀 Initializing CI/CD Dashboard Database...');

// Switch to the target database
db = db.getSiblingDB('cicd-dashboard');

// Create collections with proper indexes
print('📊 Creating collections and indexes...');

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

print('✅ Database initialization completed successfully!');

// Insert sample data for development/testing
if (process.env.NODE_ENV === 'development' || process.env.INSERT_SAMPLE_DATA === 'true') {
    print('🧪 Inserting sample data for development...');
    
    // Sample pipeline data
    const samplePipelines = [
        {
            name: "frontend-build",
            url: "http://44.249.60.108:8080/job/frontend-build",
            color: "blue",
            last_updated: new Date(),
            info: {
                description: "Frontend application build pipeline",
                healthReport: [{ score: 100, description: "Build stability: 100%" }]
            }
        },
        {
            name: "backend-api",
            url: "http://44.249.60.108:8080/job/backend-api",
            color: "blue",
            last_updated: new Date(),
            info: {
                description: "Backend API build and test pipeline",
                healthReport: [{ score: 95, description: "Build stability: 95%" }]
            }
        },
        {
            name: "integration-tests",
            url: "http://44.249.60.108:8080/job/integration-tests",
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
            url: "http://44.249.60.108:8080/job/frontend-build/123",
            timestamp: new Date(Date.now() - 3600000), // 1 hour ago
            status: "SUCCESS",
            duration: 180, // 3 minutes
            estimated_duration: 200,
            executor: { currentExecutable: { number: 123 } },
            last_updated: new Date()
        },
        {
            pipeline_name: "frontend-build",
            build_number: 122,
            url: "http://44.249.60.108:8080/job/frontend-build/122",
            timestamp: new Date(Date.now() - 7200000), // 2 hours ago
            status: "SUCCESS",
            duration: 165,
            estimated_duration: 200,
            executor: { currentExecutable: { number: 122 } },
            last_updated: new Date()
        },
        {
            pipeline_name: "backend-api",
            build_number: 89,
            url: "http://44.249.60.108:8080/job/backend-api/89",
            timestamp: new Date(Date.now() - 1800000), // 30 minutes ago
            status: "SUCCESS",
            duration: 420, // 7 minutes
            estimated_duration: 450,
            executor: { currentExecutable: { number: 89 } },
            last_updated: new Date()
        },
        {
            pipeline_name: "integration-tests",
            build_number: 67,
            url: "http://44.249.60.108:8080/job/integration-tests/67",
            timestamp: new Date(Date.now() - 900000), // 15 minutes ago
            status: "FAILURE",
            duration: 1200, // 20 minutes
            estimated_duration: 900,
            executor: { currentExecutable: { number: 67 } },
            last_updated: new Date()
        }
    ];
    
    db.builds.insertMany(sampleBuilds);
    
    // Sample metrics data
    const sampleMetrics = [
        {
            pipeline_name: "frontend-build",
            date: new Date().toISOString().split('T')[0],
            total_builds: 2,
            successful_builds: 2,
            failed_builds: 0,
            success_rate: 100.0,
            avg_duration: 172.5,
            total_duration: 345
        },
        {
            pipeline_name: "backend-api",
            date: new Date().toISOString().split('T')[0],
            total_builds: 1,
            successful_builds: 1,
            failed_builds: 0,
            success_rate: 100.0,
            avg_duration: 420.0,
            total_duration: 420
        },
        {
            pipeline_name: "integration-tests",
            date: new Date().toISOString().split('T')[0],
            total_builds: 1,
            successful_builds: 0,
            failed_builds: 1,
            success_rate: 0.0,
            avg_duration: 1200.0,
            total_duration: 1200
        }
    ];
    
    db.metrics.insertMany(sampleMetrics);
    
    print('✅ Sample data inserted successfully!');
}

print('🎉 CI/CD Dashboard database is ready!');
print(`📈 Collections created: ${db.getCollectionNames().join(', ')}`);
print(`🔍 Total pipelines: ${db.pipelines.countDocuments()}`);
print(`🔨 Total builds: ${db.builds.countDocuments()}`);
print(`📊 Total metrics: ${db.metrics.countDocuments()}`);

