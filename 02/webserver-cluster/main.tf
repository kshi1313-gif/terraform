# 1. 기본 인프라: default VPC, default subnet
# 2. 작성 인프라:
# (1). ELB 생성
# 1) SG
# 2) TG
# 3) LB
# 4) LB Listener
# 5) LB Listener rule
# (2). ASG(TG) 생성 
# 1) SG
# 2) LT
# 3) ASG

# 1. 기본 인프라: default VPC, default subnet
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/vpc
data "aws_vpc" "default" {
  default = true
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/subnets
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# 2. 작성 인프라:
# (1). ELB 생성
# 1) SG
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group#example-usage
# * 80/tcp, 443/tcp
resource "aws_security_group" "myLB_SG" {
  name        = var.myLBname
  description = "Allow 80/tcp, 443/tcp inbound traffic and all outbound traffic"
  vpc_id      = data.aws_vpc.default.id
  tags        = local.myLB_SG_tag
}

resource "aws_vpc_security_group_ingress_rule" "myLB_80" {
  security_group_id = aws_security_group.myLB_SG.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

resource "aws_vpc_security_group_ingress_rule" "myLB_443" {
  security_group_id = aws_security_group.myLB_SG.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  ip_protocol       = "tcp"
  to_port           = 443
}

resource "aws_vpc_security_group_egress_rule" "myLB_all" {
  security_group_id = aws_security_group.myLB_SG.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}

# 2) TG
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_target_group#example-usage
resource "aws_lb_target_group" "myLB_TG" {
  name     = "myLB-TG"
  port     = var.myLB_TG_port
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.default.id
}

# 3) LB
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb#example-usage
resource "aws_lb" "myLB" {
  name               = "myLB"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.myLB_SG.id]
  subnets            = data.aws_subnets.default.ids
}

# 4) LB Listener
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener#example-usage
resource "aws_lb_listener" "myLB_Listener" {
  load_balancer_arn = aws_lb.myLB.arn
  port              = var.myLB_Listener_port
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.myLB_TG.arn
  }
}

# 5) LB Listener rule
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener_rule#example-usage
resource "aws_lb_listener_rule" "myLB_Listener_rule" {
  listener_arn = aws_lb_listener.myLB_Listener.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.myLB_TG.arn
  }

  condition {
    path_pattern {
      values = ["*"]
    }
  }
}

# (2). ASG(TG)) 생성 
# 1) SG
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group#example-usage
# * 80/tcp, 443/tcp
resource "aws_security_group" "myASG_SG" {
  name        = var.myASGname
  description = "Allow 80/tcp, 443/tcp inbound traffic and all outbound traffic"
  vpc_id      = data.aws_vpc.default.id
  tags        = local.myASG_SG_tag
}

resource "aws_vpc_security_group_ingress_rule" "myASG_80" {
  security_group_id = aws_security_group.myASG_SG.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

resource "aws_vpc_security_group_ingress_rule" "myASG_443" {
  security_group_id = aws_security_group.myASG_SG.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  ip_protocol       = "tcp"
  to_port           = 443
}

resource "aws_vpc_security_group_egress_rule" "myASG_all" {
  security_group_id = aws_security_group.myASG_SG.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}


# 2) LT(launch_template)
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/launch_template#example-usage
# * image_id
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance#example-usage
data "aws_ami" "amz2023ami" {
  most_recent = true

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-kernel-6.18-x86_64*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["137112412989"] # Canonical
}

resource "aws_key_pair" "mykeypair" {
  key_name   = "mykeypair"
  public_key = file("~/.ssh/mykeypair.pub")
}

resource "aws_launch_template" "myLT" {
  name                   = "myLT"
  image_id               = data.aws_ami.amz2023ami.id
  instance_type          = "t3.micro"
  key_name               = "mykeypair"
  vpc_security_group_ids = [aws_security_group.myASG_SG.id]
  user_data              = filebase64("user_data.sh")
}

# 3) ASG
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_group
resource "aws_autoscaling_group" "myASG" {
  vpc_zone_identifier = data.aws_subnets.default.ids
  desired_capacity    = 2
  max_size            = 10
  min_size            = 1

  target_group_arns = [aws_lb_target_group.myLB_TG.arn]
  depends_on        = [aws_lb_target_group.myLB_TG]

  launch_template {
    id      = aws_launch_template.myLT.id
    version = "$Latest"
  }
}
