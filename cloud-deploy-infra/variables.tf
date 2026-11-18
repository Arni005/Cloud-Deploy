variable "key_name" {
  description = "Name of the AWS key pair for SSH access"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "ap-south-1"
}

variable "ami_id" {
  description = "AMI ID for EC2 instances"
  type        = string
  default     = "ami-09d8c1e69d114dbf7"
}

variable "server_instance_type" {
  description = "EC2 instance type for the K3s server"
  type        = string
  default     = "c7i-flex.large"
}

variable "worker_instance_type" {
  description = "EC2 instance type for K3s workers"
  type        = string
  default     = "t3.small"
}