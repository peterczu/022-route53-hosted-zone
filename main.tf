resource "aws_vpc" "alb" {

  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "alb-app-vpc"
  }
}

resource "aws_subnet" "public_a" {

  vpc_id = aws_vpc.alb.id

  cidr_block = "10.0.1.0/24"

  availability_zone = "eu-north-1a"

  map_public_ip_on_launch = true

  tags = {
    Name = "alb-app-public-a-subnet"
  }
}


resource "aws_subnet" "public_b" {

  vpc_id = aws_vpc.alb.id

  cidr_block = "10.0.2.0/24"

  availability_zone = "eu-north-1b"

  map_public_ip_on_launch = true

  tags = {
    Name = "alb-app-public-b-subnet"
  }
}

resource "aws_internet_gateway" "igw" {

  vpc_id = aws_vpc.alb.id

  tags = {
    Name = "alb-app-igw"
  }

}

resource "aws_route_table" "public" {

  vpc_id = aws_vpc.alb.id

  tags = {
    Name = "alb-app-public-route-table"
  }

}

resource "aws_route" "internet_access" {

  route_table_id = aws_route_table.public.id

  destination_cidr_block = "0.0.0.0/0"

  gateway_id = aws_internet_gateway.igw.id

}


resource "aws_route_table_association" "public_a" {

  subnet_id = aws_subnet.public_a.id

  route_table_id = aws_route_table.public.id

}

resource "aws_route_table_association" "public_b" {

  subnet_id = aws_subnet.public_b.id

  route_table_id = aws_route_table.public.id

}


resource "aws_security_group" "alb" {

  name        = "alb-security-group"
  description = "Allow HTTP 80 from ALB"
  vpc_id      = aws_vpc.alb.id

  ingress {

    description = "HTTP"

    from_port = 80
    to_port   = 80

    protocol = "tcp"

    cidr_blocks = ["0.0.0.0/0"]

  }

  ingress {

    description = "HTTPS"

    from_port = 443
    to_port   = 443

    protocol = "tcp"

    cidr_blocks = ["0.0.0.0/0"]

  }

  egress {

    from_port = 0
    to_port   = 0

    protocol = "-1"

    cidr_blocks = ["0.0.0.0/0"]

  }

  tags = {
    Name = "alb-app-sg"
  }

}

resource "aws_security_group" "web" {

  name        = "web-security-group"
  description = "Allow SSH"
  vpc_id      = aws_vpc.alb.id

  ingress {
    description = "SSH"

    from_port = 22
    to_port   = 22

    protocol = "tcp"

    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {

    description = "HTTP"

    from_port = 80
    to_port   = 80

    protocol = "tcp"

    cidr_blocks = ["0.0.0.0/0"]

  }

  egress {

    from_port = 0
    to_port   = 0

    protocol = "-1"

    cidr_blocks = ["0.0.0.0/0"]

  }

  tags = {
    Name = "alb-app-web-sg"
  }

}







resource "aws_lb" "app" {

  name = "alb-app"

  internal = false

  load_balancer_type = "application"

  security_groups = [
    aws_security_group.alb.id
  ]

  subnets = [
    aws_subnet.public_a.id,
    aws_subnet.public_b.id
  ]

  tags = {
    Name = "alb-app"
  }

}


data "aws_ami" "amazon_linux" {

  most_recent = true

  owners = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

}

resource "aws_launch_template" "web" {

  name_prefix = "alb-web-"

  image_id = data.aws_ami.amazon_linux.id

  instance_type = var.instance_type

  key_name = var.key_name

  iam_instance_profile {

    name = aws_iam_instance_profile.ec2.name

  }

  vpc_security_group_ids = [
    aws_security_group.web.id
  ]

  user_data = base64encode(<<-EOF
#!/bin/bash

dnf update -y
dnf install -y nginx

systemctl enable nginx
systemctl start nginx

cat > /usr/share/nginx/html/index.html <<HTML
<html>
<body>
<h1>Hello from Auto Scaling Group</h1>
</body>
</html>
HTML
EOF
  )

  tag_specifications {

    resource_type = "instance"

    tags = {
      Name = "alb-web"
    }

  }

}


resource "aws_autoscaling_group" "web" {

  name = "alb-web-asg"

  min_size         = 2
  max_size         = 4
  desired_capacity = 2

  vpc_zone_identifier = [
    aws_subnet.private_a.id,
    aws_subnet.private_b.id
  ]

  target_group_arns = [
    aws_lb_target_group.web.arn
  ]

  launch_template {

    id      = aws_launch_template.web.id
    version = "$Latest"

  }

  health_check_type = "ELB"

  tag {

    key                 = "Name"
    value               = "alb-web"
    propagate_at_launch = true

  }

}


resource "aws_lb_target_group" "web" {

  name     = "alb-web-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.alb.id

  health_check {
    path = "/"

    protocol = "HTTP"

    matcher = "200"
  }

  tags = {
    Name = "alb-web-target-group"
  }

}


resource "aws_lb_listener" "http" {

  load_balancer_arn = aws_lb.app.arn

  port     = 80
  protocol = "HTTP"

  default_action {

    type = "redirect"

    redirect {

      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"

    }

  }

}

resource "aws_autoscaling_policy" "scale_out" {

  name = "scale-out"

  autoscaling_group_name = aws_autoscaling_group.web.name

  adjustment_type = "ChangeInCapacity"

  scaling_adjustment = 1

  cooldown = 300
}

resource "aws_autoscaling_policy" "scale_in" {

  name = "scale-in"

  autoscaling_group_name = aws_autoscaling_group.web.name

  adjustment_type = "ChangeInCapacity"

  scaling_adjustment = -1

  cooldown = 300
}

resource "aws_cloudwatch_metric_alarm" "high_cpu" {

  alarm_name = "high-cpu"

  comparison_operator = "GreaterThanOrEqualToThreshold"

  evaluation_periods = 2

  metric_name = "CPUUtilization"

  namespace = "AWS/EC2"

  period = 120

  statistic = "Average"

  threshold = 70

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.web.name
  }

  alarm_actions = [
    aws_autoscaling_policy.scale_out.arn
  ]
}


resource "aws_subnet" "private_a" {

  vpc_id = aws_vpc.alb.id

  cidr_block = "10.0.3.0/24"

  availability_zone = "eu-north-1a"


  tags = {
    Name = "alb-app-private-a-subnet"
  }
}


resource "aws_subnet" "private_b" {

  vpc_id = aws_vpc.alb.id

  cidr_block = "10.0.4.0/24"

  availability_zone = "eu-north-1b"


  tags = {
    Name = "alb-app-private-b-subnet"
  }
}




resource "aws_route_table" "private" {

  vpc_id = aws_vpc.alb.id

  tags = {
    Name = "alb-app-private-route-table"
  }

}


resource "aws_route_table_association" "private_a" {

  subnet_id = aws_subnet.private_a.id

  route_table_id = aws_route_table.private.id

}

resource "aws_route_table_association" "private_b" {

  subnet_id = aws_subnet.private_b.id

  route_table_id = aws_route_table.private.id

}

resource "aws_db_subnet_group" "main" {

  name = "alb-app-db-subnet-group"

  subnet_ids = [
    aws_subnet.private_a.id,
    aws_subnet.private_b.id
  ]

  tags = {
    Name = "alb-app-db-subnet-group"
  }

}


resource "aws_security_group" "rds" {

  name        = "alb-rds-security-group"
  description = "Allow MySQL from EC2 web servers"
  vpc_id      = aws_vpc.alb.id

  ingress {

    description = "MySQL"

    from_port = 3306
    to_port   = 3306

    protocol = "tcp"

    security_groups = [
      aws_security_group.web.id
    ]
  }

  egress {

    from_port = 0
    to_port   = 0

    protocol = "-1"

    cidr_blocks = ["0.0.0.0/0"]

  }

  tags = {
    Name = "alb-app-rds-sg"
  }

}


resource "aws_db_instance" "main" {

  identifier = "alb-app-db"

  engine         = "mysql"
  engine_version = "8.0"

  instance_class = "db.t3.micro"

  allocated_storage       = 20
  storage_type            = "gp3"
  deletion_protection     = false
  db_name                 = "appdb"
  backup_retention_period = 0
  multi_az                = false
  username                = var.db_username
  password                = var.db_password

  db_subnet_group_name = aws_db_subnet_group.main.name

  vpc_security_group_ids = [
    aws_security_group.rds.id
  ]

  publicly_accessible = false

  skip_final_snapshot = true

}


resource "aws_eip" "nat" {

  domain = "vpc"

  tags = {
    Name = "alb-app-nat-eip"
  }

}


resource "aws_nat_gateway" "main" {

  allocation_id = aws_eip.nat.id

  subnet_id = aws_subnet.public_a.id

  tags = {
    Name = "alb-app-nat-gateway"
  }

}


resource "aws_route" "private_outbound_internet" {

  route_table_id = aws_route_table.private.id

  destination_cidr_block = "0.0.0.0/0"

  nat_gateway_id = aws_nat_gateway.main.id

}



resource "aws_lb_listener" "https" {

  load_balancer_arn = aws_lb.app.arn

  port     = 443
  protocol = "HTTPS"

  ssl_policy = "ELBSecurityPolicy-2016-08"

  certificate_arn = "arn:aws:acm:eu-north-1:465137781188:certificate/9bc57b0d-6b89-4ee1-95c9-12e4b0315379"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web.arn
  }
}



resource "aws_route53_record" "app" {

  zone_id = "Z04634032TBO0JQM0EY87"

  name = "www.devopspomadueke.xyz"

  type = "A"

  alias {

    name = aws_lb.app.dns_name

    zone_id = aws_lb.app.zone_id

    evaluate_target_health = true

  }

}


resource "aws_route53_record" "root" {

  zone_id = "Z04634032TBO0JQM0EY87"

  name = "devopspomadueke.xyz"

  type = "A"

  alias {

    name = aws_lb.app.dns_name

    zone_id = aws_lb.app.zone_id

    evaluate_target_health = true

  }

}
