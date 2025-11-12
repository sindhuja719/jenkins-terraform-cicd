output "jenkins_master_public_ip" {
  value = aws_instance.jenkins_master.public_ip
}

output "jenkins_agent_public_ip" {
  value = aws_instance.jenkins_agent.public_ip
}

output "jenkins_master_url" {
  value = "http://${aws_instance.jenkins_master.public_ip}:9090"
}

output "flask_app_url" {
  value = "http://100.27.33.157:5000"
}
