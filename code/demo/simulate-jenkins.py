#!/usr/bin/env python3
"""
Jenkins Pipeline Data Simulator
This script simulates Jenkins pipeline data for testing the CI/CD dashboard
"""

import requests
import json
import time
import random
from datetime import datetime, timedelta
import threading

class JenkinsSimulator:
    def __init__(self, dashboard_url="http://localhost:5000"):
        self.dashboard_url = dashboard_url
        self.running = False
        
        # Simulated pipeline configurations
        self.pipelines = [
            {
                "name": "frontend-build",
                "description": "Frontend application build and test pipeline",
                "success_rate": 0.95,
                "avg_duration": 180,  # 3 minutes
                "failure_probability": 0.05
            },
            {
                "name": "backend-api",
                "description": "Backend API build and test pipeline",
                "success_rate": 0.90,
                "avg_duration": 420,  # 7 minutes
                "failure_probability": 0.10
            },
            {
                "name": "integration-tests",
                "description": "Integration test suite execution",
                "success_rate": 0.85,
                "avg_duration": 900,  # 15 minutes
                "failure_probability": 0.15
            },
            {
                "name": "deployment-prod",
                "description": "Production deployment pipeline",
                "success_rate": 0.98,
                "avg_duration": 300,  # 5 minutes
                "failure_probability": 0.02
            },
            {
                "name": "security-scan",
                "description": "Security vulnerability scanning",
                "success_rate": 0.92,
                "avg_duration": 600,  # 10 minutes
                "failure_probability": 0.08
            }
        ]
        
        self.build_numbers = {pipeline["name"]: 100 for pipeline in self.pipelines}
        
    def simulate_pipeline_execution(self, pipeline_config):
        """Simulate a single pipeline execution"""
        pipeline_name = pipeline_config["name"]
        self.build_numbers[pipeline_name] += 1
        build_number = self.build_numbers[pipeline_name]
        
        # Determine build status based on success rate
        if random.random() < pipeline_config["success_rate"]:
            status = "SUCCESS"
            color = "blue"
        else:
            status = "FAILURE"
            color = "red"
        
        # Calculate build duration with some variance
        base_duration = pipeline_config["avg_duration"]
        variance = random.uniform(0.8, 1.2)
        duration = int(base_duration * variance)
        
        # Simulate build timestamp
        timestamp = datetime.now() - timedelta(minutes=random.randint(1, 60))
        
        # Create build data
        build_data = {
            "pipeline_name": pipeline_name,
            "build_number": build_number,
            "url": f"http://44.249.60.108:8080/job/{pipeline_name}/{build_number}",
            "timestamp": timestamp.isoformat(),
            "status": status,
            "duration": duration,
            "estimated_duration": base_duration,
            "executor": {"currentExecutable": {"number": build_number}},
            "last_updated": datetime.now().isoformat()
        }
        
        # Update pipeline status
        pipeline_update = {
            "name": pipeline_name,
            "url": f"http://44.249.60.108:8080/job/{pipeline_name}",
            "color": color,
            "last_updated": datetime.now().isoformat(),
            "info": {
                "description": pipeline_config["description"],
                "healthReport": [{"score": int(pipeline_config["success_rate"] * 100), "description": f"Build stability: {int(pipeline_config["success_rate"] * 100)}%"}]
            }
        }
        
        return build_data, pipeline_update
    
    def send_to_dashboard(self, endpoint, data):
        """Send data to the dashboard API"""
        try:
            url = f"{self.dashboard_url}{endpoint}"
            response = requests.post(url, json=data, timeout=5)
            if response.status_code == 200:
                print(f"✅ Sent data to {endpoint}")
            else:
                print(f"⚠️  Failed to send data to {endpoint}: {response.status_code}")
        except requests.exceptions.RequestException as e:
            print(f"❌ Error sending data to {endpoint}: {e}")
    
    def simulate_build_cycle(self):
        """Simulate a complete build cycle for all pipelines"""
        print(f"\n🔄 Simulating build cycle at {datetime.now().strftime('%H:%M:%S')}")
        
        for pipeline_config in self.pipelines:
            try:
                # Simulate pipeline execution
                build_data, pipeline_update = self.simulate_pipeline_execution(pipeline_config)
                
                # Send build data to dashboard
                self.send_to_dashboard("/api/builds", build_data)
                
                # Send pipeline update to dashboard
                self.send_to_dashboard("/api/pipelines", pipeline_update)
                
                # Add some delay between pipelines
                time.sleep(random.uniform(1, 3))
                
            except Exception as e:
                print(f"❌ Error simulating {pipeline_config['name']}: {e}")
    
    def start_simulation(self, interval_minutes=5):
        """Start the continuous simulation"""
        self.running = True
        print(f"🚀 Starting Jenkins simulation (interval: {interval_minutes} minutes)")
        print(f"📊 Simulating {len(self.pipelines)} pipelines")
        print(f"🔗 Dashboard URL: {self.dashboard_url}")
        
        # Initial simulation
        self.simulate_build_cycle()
        
        # Continuous simulation
        while self.running:
            try:
                time.sleep(interval_minutes * 60)  # Convert to seconds
                if self.running:
                    self.simulate_build_cycle()
            except KeyboardInterrupt:
                print("\n⏹️  Simulation stopped by user")
                break
            except Exception as e:
                print(f"❌ Simulation error: {e}")
                time.sleep(30)  # Wait before retrying
    
    def stop_simulation(self):
        """Stop the simulation"""
        self.running = False
        print("⏹️  Stopping simulation...")
    
    def generate_historical_data(self, days=7):
        """Generate historical data for the past N days"""
        print(f"📚 Generating {days} days of historical data...")
        
        for pipeline_config in self.pipelines:
            pipeline_name = pipeline_config["name"]
            print(f"  📊 Generating data for {pipeline_name}...")
            
            # Generate builds for each day
            for day in range(days, 0, -1):
                date = datetime.now() - timedelta(days=day)
                
                # Generate 3-8 builds per day
                builds_per_day = random.randint(3, 8)
                
                for build in range(builds_per_day):
                    self.build_numbers[pipeline_name] += 1
                    build_number = self.build_numbers[pipeline_name]
                    
                    # Determine status based on success rate
                    if random.random() < pipeline_config["success_rate"]:
                        status = "SUCCESS"
                    else:
                        status = "FAILURE"
                    
                    # Calculate duration
                    base_duration = pipeline_config["avg_duration"]
                    variance = random.uniform(0.8, 1.2)
                    duration = int(base_duration * variance)
                    
                    # Random time during the day
                    build_time = date + timedelta(
                        hours=random.randint(0, 23),
                        minutes=random.randint(0, 59)
                    )
                    
                    build_data = {
                        "pipeline_name": pipeline_name,
                        "build_number": build_number,
                        "url": f"http://44.249.60.108:8080/job/{pipeline_name}/{build_number}",
                        "timestamp": build_time.isoformat(),
                        "status": status,
                        "duration": duration,
                        "estimated_duration": base_duration,
                        "executor": {"currentExecutable": {"number": build_number}},
                        "last_updated": datetime.now().isoformat()
                    }
                    
                    # Send historical build data
                    self.send_to_dashboard("/api/builds", build_data)
                    
                    # Small delay to avoid overwhelming the API
                    time.sleep(0.1)
        
        print("✅ Historical data generation completed!")

def main():
    """Main function to run the simulator"""
    import argparse
    
    parser = argparse.ArgumentParser(description="Jenkins Pipeline Data Simulator")
    parser.add_argument("--url", default="http://localhost:5000", help="Dashboard API URL")
    parser.add_argument("--interval", type=int, default=5, help="Simulation interval in minutes")
    parser.add_argument("--historical", type=int, default=0, help="Generate N days of historical data")
    
    args = parser.parse_args()
    
    simulator = JenkinsSimulator(args.url)
    
    try:
        if args.historical > 0:
            simulator.generate_historical_data(args.historical)
        
        if args.interval > 0:
            simulator.start_simulation(args.interval)
        else:
            simulator.simulate_build_cycle()
            
    except KeyboardInterrupt:
        print("\n👋 Goodbye!")
    except Exception as e:
        print(f"❌ Fatal error: {e}")

if __name__ == "__main__":
    main()

