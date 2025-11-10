########################################
# Provider Configuration
########################################
provider "aws" {
  region = "us-east-1"
}

########################################
# Key Pair
########################################
variable "public_key" {
  description = "Public SSH key contents for EC2 key pair"
  type        = string
}
###############################################
resource "random_id" "suffix" {
  byte_length = 2
}

###############################################
# KEY PAIR
###############################################
resource "aws_key_pair" "jenkins_key" {
  key_name   = "jenkins-fresh-key-${random_id.suffix.hex}"
  public_key = var.public_key
}


########################################
# Networking - VPC, Subnet, IGW, Route Table
########################################
resource "aws_vpc" "jenkins_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = { Name = "jenkins-vpc" }
}

resource "aws_internet_gateway" "jenkins_gw" {
  vpc_id = aws_vpc.jenkins_vpc.id
  tags = { Name = "jenkins-gateway" }
}

resource "aws_subnet" "jenkins_subnet" {
  vpc_id                  = aws_vpc.jenkins_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1a"
  tags = { Name = "jenkins-public-subnet" }
}

resource "aws_route_table" "jenkins_route_table" {
  vpc_id = aws_vpc.jenkins_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.jenkins_gw.id
  }
}

resource "aws_route_table_association" "jenkins_route_assoc" {
  subnet_id      = aws_subnet.jenkins_subnet.id
  route_table_id = aws_route_table.jenkins_route_table.id
}

########################################
# Security Group
########################################
resource "aws_security_group" "jenkins_sg" {
  name        = "jenkins-sg-new"
  description = "Allow SSH, Jenkins web, and agent traffic"
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

  tags = { Name = "jenkins-sg" }
}

########################################
# Jenkins Master Instance
########################################
resource "aws_instance" "jenkins_master" {
  ami                         = "ami-0c7217cdde317cfec" # Ubuntu 22.04
  instance_type               = "t3.micro"
  subnet_id                   = aws_subnet.jenkins_subnet.id
  key_name                    = aws_key_pair.jenkins_key.key_name
  vpc_security_group_ids      = [aws_security_group.jenkins_sg.id]
  associate_public_ip_address = true

  # ----------- Install Docker, Terraform, AWS CLI, Jenkins ------------
  user_data = <<-EOF
    #!/bin/bash
    apt update -y
    apt install -y apt-transport-https ca-certificates curl gnupg lsb-release unzip git openjdk-17-jdk

    # Docker installation
    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
      $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
    apt update -y
    apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
    systemctl enable docker
    systemctl start docker
    usermod -aG docker ubuntu

    # Terraform installation
    curl -fsSL https://releases.hashicorp.com/terraform/1.9.7/terraform_1.9.7_linux_amd64.zip -o terraform.zip
    unzip terraform.zip
    mv terraform /usr/local/bin/
    rm terraform.zip

    # AWS CLI installation
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip awscliv2.zip
    ./aws/install

    # Jenkins in Docker
    mkdir -p /home/ubuntu/jenkins_home
    docker run -d --name jenkins-master -p 9090:8080 -p 50000:50000 \
      -v /home/ubuntu/jenkins_home:/var/jenkins_home \
      jenkins/jenkins:lts
  EOF

  tags = { Name = "Jenkins-Master" }
}

########################################
# Jenkins Agent Instance
########################################
resource "aws_instance" "jenkins_agent" {
  ami                         = "ami-0c7217cdde317cfec" # Ubuntu 22.04
  instance_type               = "t3.micro"
  subnet_id                   = aws_subnet.jenkins_subnet.id
  key_name                    = aws_key_pair.jenkins_key.key_name
  vpc_security_group_ids      = [aws_security_group.jenkins_sg.id]
  associate_public_ip_address = true

  # ----------- Install Docker, Terraform, AWS CLI, Git, Java ------------
  user_data = <<-EOF
    #!/bin/bash
    apt update -y
    apt install -y apt-transport-https ca-certificates curl gnupg lsb-release unzip git openjdk-17-jdk

    # Docker installation
    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
      $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
    apt update -y
    apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
    systemctl enable docker
    systemctl start docker
    usermod -aG docker ubuntu

    # Terraform installation
    curl -fsSL https://releases.hashicorp.com/terraform/1.9.7/terraform_1.9.7_linux_amd64.zip -o terraform.zip
    unzip terraform.zip
    mv terraform /usr/local/bin/
    rm terraform.zip

    # AWS CLI installation
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip awscliv2.zip
    ./aws/install
  EOF

  tags = { Name = "Jenkins-Agent" }
}

########################################
# Elastic IPs (Permanent IPs)
########################################
resource "aws_eip" "jenkins_master_eip" {
  instance   = aws_instance.jenkins_master.id
  depends_on = [aws_instance.jenkins_master]
  tags = { Name = "jenkins-master-eip" }
}

resource "aws_eip" "jenkins_agent_eip" {
  instance   = aws_instance.jenkins_agent.id
  depends_on = [aws_instance.jenkins_agent]
  tags = { Name = "jenkins-agent-eip" }
}

########################################
# Outputs
########################################
output "jenkins_master_public_ip" {
  value = aws_eip.jenkins_master_eip.public_ip
}

output "jenkins_agent_public_ip" {
  value = aws_eip.jenkins_agent_eip.public_ip
}

output "jenkins_master_url" {
  value = "http://${aws_eip.jenkins_master_eip.public_ip}:9090"
}
