resource "aws_security_group" "ec2" {
  name   = "cloud-deploy-ec2-sg"
  vpc_id = aws_vpc.myvpc.id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Kubernetes API Server"
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
  description = "Kubelet API"
  from_port   = 10250
  to_port     = 10250
  protocol    = "tcp"
  cidr_blocks = ["10.0.0.0/16"]
 }
 
 ingress {
  description = "Flannel VXLAN"
  from_port   = 8472
  to_port     = 8472
  protocol    = "udp"
  cidr_blocks = ["10.0.0.0/16"]
}
  ingress {
  description = "etcd"
  from_port   = 2379
  to_port     = 2380
  protocol    = "tcp"
  cidr_blocks = ["10.0.0.0/16"]
}


  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }
}
