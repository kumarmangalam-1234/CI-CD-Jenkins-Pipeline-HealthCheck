# Terraform variables for CI/CD Health Dashboard Infrastructure

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

# SSH Configuration
ssh_public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDLSZgp/hG9UyZlgrXmBxQMRh47uFJbGj+AN9x1w7N/MEr7Ktq8yixb7z5j8fcYsbUXq6Ib58LsQL1tXNDiFS1fIQAESlPZ8wyJZGMsOLowME1ycy6D8GYaX1MNZHzIQH8wnTCmvJOloBGVHeg6OV5hk1aWK1ITCmvUkjdBNrj+QsZ+vObw/g3TipTeqNBhW3LRjvQoMMhNe76WEhC6LuJZdLiAljbDrcyOu+xSpAapmj8IMwGJXjeLYvZ9TwWBxJv+xxGUhhn+FN5mrD+gVRGz6nX5fICGa/I0e0fxkUVL3fjGWMLmrV6X4Dbs1vqKnVYPh4l1YW3/FA+8sTTwLKHkE/P0LLg/FWVs9EMO1zdkAio28squwxys7JAznxQ8fYvkZfmMSRWEvQTmVBtZBztvI/f5DfMl7JZJLQWUKH5eJJZquFkjhuri62CUZ+WLkP9Iqkbko3nchfEMxqnFz+x7DAL5rK3LdOgNGMOVuhX/ScUQEfxk9QtUSbtijgRsgLZ46/5vBcygrRTaBYMrqSs4eoSQwKR3oLCVvkFH1lyVCFoTqXU91LeSUXCS+pmt8cH36hWJj+MhmnjGqmtIve8qw/3iPugEiLjFSs2uyxSKNigg7/fH5JL0NNhW4/8EbzRgP5QgT928l6gwE8E1RVNSSPHz+Yg9fW5PPcRrZhFR2w== cicd-dashboard-20250919"

# Jenkins Configuration
jenkins_url = "http://44.249.60.108:8080"
jenkins_username = "admin"
jenkins_api_token = "xxx"

# Email Configuration
smtp_host = "smtp.gmail.com"
smtp_port = 587
smtp_username = "kumarmanglammishra@gmail.com"
smtp_password = "xxx"

# Slack Configuration (Optional)
slack_webhook_url = ""
