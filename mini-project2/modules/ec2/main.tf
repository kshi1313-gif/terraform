# ------------------------------------------------------------------
# modules/ec2/main.tf
# Launch Template + Auto Scaling Group (WEB/WAS EC2 x2 조건을
# 고정된 count가 아니라 ASG desired_capacity=2로 구현)
#
# 주의: 이 파일 어디에도 module.db_cluster를 직접 참조하는 코드는 없지만,
#       var.db_master_endpoint 라는 "값"이 반드시 필요하고, 그 값은
#       루트 main.tf에서 module.db_cluster.db_master_private_ip 로부터
#       채워진다. 따라서 Terraform 그래프상 이 모듈은 db 모듈 뒤에 실행된다.
# ------------------------------------------------------------------

# --- SSM Session Manager 접속용 IAM Role ---
# EC2가 Private Subnet에 있어 SSH(키페어)로 직접 접속이 안 되므로,
# AWS 콘솔/CLI의 Session Manager로 브라우저에서 바로 접속할 수 있게
# AmazonSSMManagedInstanceCore 정책을 붙인 Role을 인스턴스에 부여한다.
# (Amazon Linux 2023 AMI는 SSM Agent가 기본 설치되어 있어 Role만 있으면 바로 동작)
resource "aws_iam_role" "ssm_role" {
  name = "${var.project_name}-ec2-ssm-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ssm_core" {
  role       = aws_iam_role.ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ssm_profile" {
  name = "${var.project_name}-ec2-ssm-profile"
  role = aws_iam_role.ssm_role.name
}

resource "aws_launch_template" "web" {
  name_prefix   = "${var.project_name}-web-lt-"
  image_id      = var.web_ami_id
  instance_type = var.web_instance_type
  key_name      = var.key_name

  vpc_security_group_ids = [var.web_sg_id]

  iam_instance_profile {
    name = aws_iam_instance_profile.ssm_profile.name
  }

  # user_data는 base64 인코딩 필요
  user_data = base64encode(templatefile("${path.module}/user_data_web.sh.tpl", {
    db_host     = var.db_master_endpoint
    db_username = var.db_app_username
    db_password = var.db_app_password
    db_name     = var.db_app_name
  }))

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name    = "${var.project_name}-web"
      Project = var.project_name
    }
  }

  lifecycle {
    create_before_destroy = true # LT 변경 시 기존 걸 먼저 지우지 않고 새로 만든 후 교체
  }
}

resource "aws_autoscaling_group" "web" {
  name                = "${var.project_name}-web-asg"
  min_size            = var.asg_min
  max_size            = var.asg_max
  desired_capacity    = var.asg_desired
  vpc_zone_identifier = var.private_subnet_ids # ASG가 인스턴스를 띄울 서브넷들 (Private)
  health_check_type   = "EC2"

  launch_template {
    id      = aws_launch_template.web.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "${var.project_name}-web-asg"
    propagate_at_launch = true
  }

  # Target Group 연결(attachment)은 elb 모듈에서 담당한다.
  # (ASG가 ELB를 몰라도 되게 하여 EC2 모듈과 ELB 모듈을 느슨하게 결합)
}
