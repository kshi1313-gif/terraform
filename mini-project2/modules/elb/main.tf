# ------------------------------------------------------------------
# modules/elb/main.tf
# ALB(Application Load Balancer) + Target Group + Listener
# + ASG를 Target Group에 연결하는 attachment 리소스
#
# 이 파일이 var.asg_id를 실제로 사용하기 때문에
# (aws_autoscaling_attachment 안에서), Terraform 그래프상
# 이 모듈은 ec2_web 모듈(=db_cluster까지 포함) 뒤에 실행된다.
# ------------------------------------------------------------------

resource "aws_lb" "web_alb" {
  name               = "${var.project_name}-alb"
  internal           = false # 외부(인터넷)에서 접속 가능한 ALB
  load_balancer_type = "application"
  security_groups    = [var.alb_sg_id]
  subnets            = var.public_subnet_ids

  tags = { Name = "${var.project_name}-alb" }
}

resource "aws_lb_target_group" "web_tg" {
  name     = "${var.project_name}-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    path                = "/healthcheck.html" # ec2 모듈 user_data가 만든 파일
    protocol            = "HTTP"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    interval            = 15
    timeout             = 5
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.web_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web_tg.arn
  }
}

# ASG <-> Target Group 연결
# (ec2 모듈이 아니라 여기서 연결함으로써 EC2 모듈은 ELB 존재 여부를 몰라도 됨)
resource "aws_autoscaling_attachment" "asg_attach" {
  autoscaling_group_name = var.asg_id
  lb_target_group_arn    = aws_lb_target_group.web_tg.arn
}
