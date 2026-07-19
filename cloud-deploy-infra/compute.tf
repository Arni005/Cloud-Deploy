# K3s Server — fixed EC2, always running

resource "aws_instance" "k3s_server" {
  ami                    = "ami-0c809520a0d652e03"
  instance_type          = "t3.medium"
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.ec2.id]
  key_name               = var.key_name

  root_block_device {
    volume_size = 20
  }

  tags = {
    Name = "cloud-deploy-k3s-server"
  }
}

# K3s Worker — Launch Template

resource "aws_launch_template" "k3s_worker" {
  name_prefix   = "cloud-deploy-worker"
  image_id      = var.ami_id
  instance_type = "t3.medium"
  key_name      = var.key_name
  user_data     = base64encode(file("userdata.sh"))

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.ec2.id]
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "cloud-deploy-k3s-worker"
    }
  }
}

# K3s Worker — ASG
resource "aws_autoscaling_group" "k3s_workers" {
  desired_capacity    = 1
  min_size            = 1
  max_size            = 3

  vpc_zone_identifier = [
    aws_subnet.public.id
  ]

  launch_template {
    id      = aws_launch_template.k3s_worker.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "cloud-deploy-k3s-worker"
    propagate_at_launch = true
  }
}