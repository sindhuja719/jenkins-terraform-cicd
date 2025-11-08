terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# SSH Key
resource "aws_key_pair" "jenkins_key" {
  key_name   = "jenkins-key"
  public_key = file(var.public_key_path)
}

# Security Group for Jenkins Master & Agent
resource "aws_security_group" "jenkins_sg" {
  name        = "jenkins-sg"
  description = "Allow SSH, Jenkins web, and agent traffic"

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # For security, restrict to your IP
  }

  ingress {
    description = "Jenkins Web UI"
    from_port   = 9090
    to_port     = 9090
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Jenkins Master-Agent"
    from_port   = 50000
    to_port     = 50000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Jenkins Master EC2
resource "aws_instance" "jenkins_master" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  key_name               = aws_key_pair.jenkins_key.key_name
  vpc_security_group_ids = [aws_security_group.jenkins_sg.id]

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y docker git
              systemctl start docker
              usermod -aG docker ec2-user
              mkdir -p /home/ec2-user/jenkins_home
              docker run -d --name jenkins-master -p 9090:8080 -p 50000:50000 \
                  -v /home/ec2-user/jenkins_home:/var/jenkins_home jenkins/jenkins:lts
              EOF

  tags = {
    Name = "Jenkins-Master"
  }
}

# Jenkins Agent EC2
resource "aws_instance" "jenkins_agent" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  key_name               = aws_key_pair.jenkins_key.key_name
  vpc_security_group_ids = [aws_security_group.jenkins_sg.id]

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y java-11-amazon-corretto-headless git
              mkdir -p /home/ec2-user/.ssh
              echo "${aws_key_pair.jenkins_key.public_key}" >> /home/ec2-user/.ssh/authorized_keys
              chmod 700 /home/ec2-user/.ssh
              chmod 600 /home/ec2-user/.ssh/authorized_keys
              chown -R ec2-user:ec2-user /home/ec2-user/.ssh
              EOF

  tags = {
    Name = "Jenkins-Agent"
  }
}

# Outputs
output "jenkins_master_public_ip" {
  description = "Public IP of Jenkins Master"
  value       = aws_instance.jenkins_master.public_ip
}

output "jenkins_agent_public_ip" {
  description = "Public IP of Jenkins Agent"
  value       = aws_instance.jenkins_agent.public_ip
}

output "jenkins_master_url" {
  description = "URL of Jenkins Master Web UI"
  value       = "http://${aws_instance.jenkins_master.public_ip}:9090"
}
