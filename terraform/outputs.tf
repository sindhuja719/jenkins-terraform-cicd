output "jenkins_master_ip" {
  value       = aws_instance.jenkins_master.public_ip
  description = "Public IP address of the Jenkins Master"
}

output "jenkins_agent_ip" {
  value       = aws_instance.jenkins_agent.public_ip
  description = "Public IP address of the Jenkins Agent"
}