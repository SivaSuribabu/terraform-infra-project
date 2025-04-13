resource "aws_launch_template" "lt" {
  name_prefix   = "demo-lt-${var.env_name}"
  image_id      = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"
  vpc_security_group_ids = [aws_security_group.sg.id]
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }
}

resource "aws_autoscaling_group" "asg" {
  vpc_zone_identifier       = var.private_subnet_ids
  desired_capacity          = 1
  max_size                  = 2
  min_size                  = 1
  launch_template {
    id      = aws_launch_template.lt.id
    version = "$Latest"
  }
  health_check_type         = "EC2"
  default_cooldown          = 300
  enabled_metrics           = ["GroupDesiredCapacity", "GroupInServiceInstances"]
  tag {
    key                 = "Name"
    value               = "asg-${var.env_name}"
    propagate_at_launch = true
  }
  lifecycle {
    ignore_changes = [desired_capacity]
  }
}

resource "aws_cloudwatch_metric_alarm" "cpu_alarm" {
  alarm_name          = "cpu-high-${var.env_name}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 60
  alarm_description   = "This metric triggers when CPU exceeds 60%"
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.asg.name
  }
  alarm_actions = []
}

