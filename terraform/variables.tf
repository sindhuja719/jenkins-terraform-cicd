variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "key_name" {
  description = "Key pair name for SSH access"
  type        = string
  default     = "jenkins-fresh-key"
}

variable "instance_type" {
  description = "Instance type for Jenkins master and agent"
  type        = string
  default     = "t3.micro"
}

variable "public_key_path" {
  description = "Path to public key for AWS key pair"
  type        = string
  default     = "jenkins-new-key.pub"
}
