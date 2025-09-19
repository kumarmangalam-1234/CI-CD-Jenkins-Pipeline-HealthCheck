# Outputs for CI/CD Health Dashboard Infrastructure

output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = aws_subnet.private[*].id
}

output "public_ec2_public_ips" {
  description = "Public IP addresses of the public EC2 instances"
  value       = aws_instance.public_ec2[*].public_ip
}

output "public_ec2_private_ips" {
  description = "Private IP addresses of the public EC2 instances"
  value       = aws_instance.public_ec2[*].private_ip
}

output "private_ec2_private_ips" {
  description = "Private IP addresses of the private EC2 instances"
  value       = aws_instance.private_ec2[*].private_ip
}


output "mongodb_password" {
  description = "MongoDB root password"
  value       = random_password.mongodb_password.result
  sensitive   = true
}

output "frontend_url" {
  description = "Frontend application URL"
  value       = "http://${aws_instance.public_ec2[0].public_ip}:3000"
}

output "backend_url" {
  description = "Backend API URL"
  value       = "http://${aws_instance.public_ec2[0].public_ip}:5001"
}

output "jenkins_url" {
  description = "Jenkins CI/CD URL"
  value       = "http://${aws_instance.public_ec2[0].public_ip}:8080"
}

output "ssh_connection_public" {
  description = "SSH connection command for public EC2 instances"
  value       = "ssh -i ~/.ssh/id_rsa ec2-user@${aws_instance.public_ec2[0].public_ip}"
}

output "ssh_connection_private" {
  description = "SSH connection command for private EC2 instance (via bastion)"
  value       = "ssh -i ~/.ssh/id_rsa -J ec2-user@${aws_instance.public_ec2[0].public_ip} ec2-user@${aws_instance.private_ec2[0].private_ip}"
}
