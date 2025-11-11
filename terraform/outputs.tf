output "jenkins_master_public_ip" {
  description = "Public IP of Jenkins Master"
  value       = aws_instance.jenkins_master.public_ip
}

output "jenkins_agent_public_ip" {
  description = "Public IP of Jenkins Agent"
  value       = aws_instance.jenkins_agent.public_ip
}

output "jenkins_master_url" {
  description = "URL for Jenkins Web UI"
  value       = "http://${aws_instance.jenkins_master.public_ip}:9090"
}
output "flask_app_url" {
  description = "Public URL to access the Flask app"
  value       = "http://${aws_instance.jenkins_agent.public_ip}:5000"
}

