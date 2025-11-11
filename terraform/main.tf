provider "aws" {
  region = var.aws_region
}

# ---------- Key Pair (use existing key pair in AWS) ----------
data "aws_key_pair" "jenkins_key" {
  key_name = "jenkins-new-key"
}

# ---------- Networking ----------
resource "aws_vpc" "jenkins_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = { Name = "jenkins-vpc" }
}

resource "aws_internet_gateway" "jenkins_gw" {
  vpc_id = aws_vpc.jenkins_vpc.id
  tags   = { Name = "jenkins-gateway" }
}

resource "aws_subnet" "jenkins_subnet" {
  vpc_id                  = aws_vpc.jenkins_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = true
  tags                    = { Name = "jenkins-public-subnet" }
}

resource "aws_route_table" "jenkins_route_table" {
  vpc_id = aws_vpc.jenkins_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.jenkins_gw.id
  }
  tags = { Name = "jenkins-route-table" }
}

resource "aws_route_table_association" "jenkins_route_assoc" {
  subnet_id      = aws_subnet.jenkins_subnet.id
  route_table_id = aws_route_table.jenkins_route_table.id
}

# ---------- Security Group ----------
resource "aws_security_group" "jenkins_sg" {
  name        = "jenkins-sg"
  description = "Allow SSH, Jenkins web, and agent communication"
  vpc_id      = aws_vpc.jenkins_vpc.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Jenkins Web UI"
    from_port   = 9090
    to_port     = 9090
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Jenkins Agent Communication"
    from_port   = 50000
    to_port     = 50000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
    ingress {
    description = "Flask App"
    from_port   = 5000
    to_port     = 5000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }


  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "jenkins-sg" }
}

# ---------- Jenkins Master ----------
resource "aws_instance" "jenkins_master" {
  ami                         = "ami-007855ac798b5175e" # Ubuntu 22.04 LTS
  instance_type               = var.instance_type
  key_name                    = data.aws_key_pair.jenkins_key.key_name
  subnet_id                   = aws_subnet.jenkins_subnet.id
  vpc_security_group_ids      = [aws_security_group.jenkins_sg.id]
  associate_public_ip_address = true

  user_data = <<-EOF
    #!/bin/bash
    set -e
    apt update -y
    apt install -y apt-transport-https ca-certificates curl software-properties-common gnupg git unzip

    # Install Docker
    apt install -y docker.io
    systemctl enable docker
    systemctl start docker
    usermod -aG docker ubuntu

    # Install Java 17
    apt install -y openjdk-17-jdk

    # Install AWS CLI
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip awscliv2.zip
    ./aws/install

    # Install Terraform
    TERRAFORM_VERSION="1.9.7"
    curl -fsSL https://releases.hashicorp.com/terraform/$${TERRAFORM_VERSION}/terraform_$${TERRAFORM_VERSION}_linux_amd64.zip -o terraform.zip
    unzip terraform.zip
    mv terraform /usr/local/bin/


    # Jenkins container
    mkdir -p /home/ubuntu/jenkins_home
    chmod 777 /home/ubuntu/jenkins_home
    docker run -d --name jenkins-master -p 9090:8080 -p 50000:50000 \
      -v /home/ubuntu/jenkins_home:/var/jenkins_home \
      -v /var/run/docker.sock:/var/run/docker.sock \
      jenkins/jenkins:lts
  EOF

  tags = { Name = "Jenkins-Master" }
}

# ---------- Jenkins Agent ----------
resource "aws_instance" "jenkins_agent" {
  ami                         = "ami-007855ac798b5175e"
  instance_type               = var.instance_type
  key_name                    = data.aws_key_pair.jenkins_key.key_name
  subnet_id                   = aws_subnet.jenkins_subnet.id
  vpc_security_group_ids      = [aws_security_group.jenkins_sg.id]
  associate_public_ip_address = true

  user_data = <<-EOF
    #!/bin/bash
    set -e
    apt update -y
    apt install -y apt-transport-https ca-certificates curl software-properties-common gnupg git unzip

    # Install Docker
    apt install -y docker.io
    systemctl enable docker
    systemctl start docker
    usermod -aG docker ubuntu

    # Install Java 17
    apt install -y openjdk-17-jdk

    # Install AWS CLI
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip awscliv2.zip
    ./aws/install

    # Install Terraform
    TERRAFORM_VERSION="1.9.7"
    curl -fsSL https://releases.hashicorp.com/terraform/$${TERRAFORM_VERSION}/terraform_$${TERRAFORM_VERSION}_linux_amd64.zip -o terraform.zip
    unzip terraform.zip
    mv terraform /usr/local/bin/

  EOF

  tags = { Name = "Jenkins-Agent" }
}
