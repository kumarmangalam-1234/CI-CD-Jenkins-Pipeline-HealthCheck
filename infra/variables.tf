# Variables for CI/CD Health Dashboard Infrastructure

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-west-2"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "production"
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "cicd-dashboard"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.10.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.10.1.0/27", "10.10.2.0/27"]  # 32 IPs each
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
  default     = ["10.10.3.0/27", "10.10.4.0/27"]  # 32 IPs each
}

variable "instance_type" {
  description = "EC2 instance type for public instances"
  type        = string
  default     = "t3.medium"
}

variable "database_instance_type" {
  description = "EC2 instance type for database instance"
  type        = string
  default     = "t2.micro"
}

variable "ssh_public_key" {
  description = "SSH public key for EC2 instances"
  type        = string
  default     = ""
}

variable "jenkins_url" {
  description = "Jenkins server URL"
  type        = string
  default     = "http://host.docker.internal:4000"
}

variable "jenkins_username" {
  description = "Jenkins username"
  type        = string
  default     = "admin"
}

variable "jenkins_api_token" {
  description = "Jenkins API token"
  type        = string
  default     = "11dd97375afdede7066f2d8088fb715a15x123"
}

variable "smtp_host" {
  description = "SMTP host for email notifications"
  type        = string
  default     = "smtp.gmail.com"
}

variable "smtp_port" {
  description = "SMTP port"
  type        = number
  default     = 587
}

variable "smtp_username" {
  description = "SMTP username"
  type        = string
  default     = "kumarmanglammishra@gmail.com"
}

variable "smtp_password" {
  description = "SMTP password"
  type        = string
  default     = "bsekbmlkhkrgbjnj"
  sensitive   = true
}

variable "slack_webhook_url" {
  description = "Slack webhook URL for notifications"
  type        = string
  default     = ""
  sensitive   = true
}
