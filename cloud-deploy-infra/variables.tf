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
  default     = "ami-0c809520a0d652e03"
}