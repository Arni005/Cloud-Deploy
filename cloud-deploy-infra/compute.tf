# K3s Server
resource "aws_instance" "k3s_server" {
  ami                    = var.ami_id
  instance_type          = "t3.medium"
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.ec2.id]
  key_name               = var.key_name

  root_block_device {
    volume_size = 20
  }

  tags = {
    Name = "cloudship-k3s-server"
  }
}

# K3s Worker Launch Template
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

# K3s Workers ASG
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

# Scale up when CPU goes above 70%
resource "aws_autoscaling_policy" "scale_up" {
  name                   = "cloudship-scale-up"
  autoscaling_group_name = aws_autoscaling_group.k3s_workers.name
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = 1
  cooldown               = 300
}

resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name          = "cloudship-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 120
  statistic           = "Average"
  threshold           = 70
  alarm_description   = "Scale up when CPU above 70%"
  alarm_actions       = [aws_autoscaling_policy.scale_up.arn]

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.k3s_workers.name
  }
}

# Scale down when CPU goes below 30%
resource "aws_autoscaling_policy" "scale_down" {
  name                   = "cloudship-scale-down"
  autoscaling_group_name = aws_autoscaling_group.k3s_workers.name
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = -1
  cooldown               = 300
}

resource "aws_cloudwatch_metric_alarm" "low_cpu" {
  alarm_name          = "cloudship-low-cpu"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 120
  statistic           = "Average"
  threshold           = 30
  alarm_description   = "Scale down when CPU below 30%"
  alarm_actions       = [aws_autoscaling_policy.scale_down.arn]

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.k3s_workers.name
  }
}