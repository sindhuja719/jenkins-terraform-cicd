provider "aws" {
  region = "us-east-1"
}

# ---------- Key Pair ----------
resource "aws_key_pair" "jenkins_key" {
  key_name   = "jenkins-agent-key"
  public_key = file("/home/ubuntu/.ssh/id_rsa.pub")
}

# ---------- Security Group ----------
resource "aws_security_group" "jenkins_sg" {
  name        = "jenkins-sg-new"
  description = "Allow SSH, Jenkins web, and agent traffic"

  ingress {
    description      = "SSH"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = []
    prefix_list_ids  = []
    security_groups  = []
    self             = false
  }

  ingress {
    description      = "Jenkins Web UI"
    from_port        = 9090
    to_port          = 9090
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = []
    prefix_list_ids  = []
    security_groups  = []
    self             = false
  }

  ingress {
    description      = "Jenkins Master-Agent"
    from_port        = 50000
    to_port          = 50000
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = []
    prefix_list_ids  = []
    security_groups  = []
    self             = false
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = []
    prefix_list_ids  = []
    security_groups  = []
    self             = false
  }
}

# ---------- Jenkins Master ----------
resource "aws_instance" "jenkins_master" {
  ami             = "ami-0c7217cdde317cfec" # Amazon Linux 2
  instance_type   = "t3.micro"
  key_name        = aws_key_pair.jenkins_key.key_name
  security_groups = [aws_security_group.jenkins_sg.name]

  user_data = <<-EOF
    #!/bin/bash
    yum update -y
    yum install -y docker git java-17-amazon-corretto
    systemctl enable docker
    systemctl start docker
    usermod -aG docker ec2-user
    mkdir -p /home/ec2-user/jenkins_home
    docker run -d --name jenkins-master -p 9090:8080 -p 50000:50000 \
      -v /home/ec2-user/jenkins_home:/var/jenkins_home \
      jenkins/jenkins:lts
  EOF

  tags = {
    Name = "Jenkins-Master"
  }
}

# ---------- Jenkins Agent ----------
resource "aws_instance" "jenkins_agent" {
  ami             = "ami-0c7217cdde317cfec"
  instance_type   = "t3.micro"
  key_name        = aws_key_pair.jenkins_key.key_name
  security_groups = [aws_security_group.jenkins_sg.name]

  user_data = <<-EOF
    #!/bin/bash
    yum update -y
    yum install -y docker git java-17-amazon-corretto terraform awscli
    systemctl enable docker
    systemctl start docker
    usermod -aG docker ec2-user
  EOF

  tags = {
    Name = "Jenkins-Agent"
  }
}

# ---------- Outputs ----------
output "jenkins_master_public_ip" {
  value = aws_instance.jenkins_master.public_ip
}

output "jenkins_agent_public_ip" {
  value = aws_instance.jenkins_agent.public_ip
}

output "jenkins_master_url" {
  value = "http://${aws_instance.jenkins_master.public_ip}:9090"
}

