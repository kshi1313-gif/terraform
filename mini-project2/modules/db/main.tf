# ------------------------------------------------------------------
# modules/db/main.tf
# MariaDB EC2 인스턴스 2대 (master 1 + replica 1) 생성
# - count를 사용해 2개 리소스를 한번에 관리
# - count.index == 0 -> master, 그 외 -> replica 로 이름/역할 구분
# ------------------------------------------------------------------

# --- SSM Session Manager 접속용 IAM Role (ec2 모듈과 동일한 이유) ---
# DB도 Private Subnet이라 SSH가 안 되므로, 관리자가 직접 접속해서
# 복제 상태(SHOW SLAVE STATUS 등)를 확인하려면 이 Role이 필요하다.
resource "aws_iam_role" "ssm_role" {
  name = "${var.project_name}-db-ssm-role"

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
  name = "${var.project_name}-db-ssm-profile"
  role = aws_iam_role.ssm_role.name
}

resource "aws_instance" "db" {
  count = 2 # DB Cluster x 2 조건 반영

  ami                    = var.db_ami_id
  instance_type          = var.db_instance_type
  key_name               = var.key_name
  # element()로 서브넷 목록을 순환 배정 -> 서로 다른 AZ에 배치되어 가용성 확보
  subnet_id              = element(var.private_subnet_ids, count.index)
  vpc_security_group_ids = [var.db_sg_id]
  iam_instance_profile   = aws_iam_instance_profile.ssm_profile.name

  user_data = templatefile("${path.module}/user_data_db.sh.tpl", {
    role             = count.index == 0 ? "master" : "replica"
    db_root_password = var.db_root_password
    db_app_username  = var.db_app_username
    db_app_password  = var.db_app_password
    db_app_name      = var.db_app_name
  })

  tags = {
    Name    = count.index == 0 ? "${var.project_name}-db-master" : "${var.project_name}-db-replica"
    Role    = count.index == 0 ? "master" : "replica"
    Project = var.project_name
  }
}
