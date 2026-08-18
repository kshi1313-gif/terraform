# ------------------------------------------------------------------
# main.tf (루트)
#
# [ 설계 포인트 ]
# 1. Security Group 3개(alb_sg, web_sg, db_sg)는 "모듈 안"이 아니라
#    루트에 둔다.
#    이유: db_sg는 "web_sg에서 오는 3306 트래픽만 허용"해야 하는데,
#          만약 web_sg가 ec2 모듈 안에 있으면 db 모듈이 ec2 모듈을
#          참조해야 해서 db → ec2 순서가 뒤바뀌는 순환 의존성이 생김.
#          (우리가 원하는 순서는 DB가 먼저 만들어지는 것)
#    → SG는 순서에 영향 없는 "지원 리소스"이므로 루트에서 미리 만들고,
#       각 모듈은 SG ID만 변수로 전달받는다.
#
# 2. 실제 실행 순서(의존성)는 SG가 아니라 "output→input 전달"로 만든다.
#      db_cluster 모듈의 output(db_master_private_ip)
#         → ec2_web 모듈의 input(user_data 안에서 DB 접속정보로 사용)
#      ec2_web 모듈의 output(asg_id)
#         → elb 모듈의 input(Target Group에 ASG 연결)
#    이렇게 실제 값을 참조해서 쓰기 때문에,
#    DB 생성이 실패하면 output이 존재하지 않아 ec2_web, elb는
#    plan/apply 단계에서 아예 진행되지 않는다.
# ------------------------------------------------------------------

# --- 0) VPC/Subnet 신규 생성 (자료 조건: 기존 VPC 재사용 금지) ---
# net module에 해당. IGW, Public Subnet x2, Private Subnet x2,
# NAT Gateway, Route Table까지 이 모듈 하나에서 처리한다.
module "vpc" {
  source = "./modules/vpc"

  project_name         = var.project_name
  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
}

# --- (A) AMI 자동 조회: 최신 Amazon Linux 2023(x86_64) ---
# web/db 모두 동일 AMI 사용. owners = "amazon" (공식 이미지만),
# most_recent = true 로 항상 최신 패치 버전을 가져온다.
# (AMI는 민감정보가 아니라 자동조회 유지 - 매번 최신 보안패치 이미지를 쓰는 게 이득)
data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# --- 1) ALB용 Security Group: 외부(인터넷) -> ALB 80/443 허용 ---
resource "aws_security_group" "alb_sg" {
  name        = "${var.project_name}-alb-sg"
  description = "Allow HTTP/HTTPS from Internet to ALB"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "HTTP from Internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.project_name}-alb-sg" }
}

# --- 2) WEB/WAS(EC2)용 Security Group: ALB -> EC2 80 허용 ---
resource "aws_security_group" "web_sg" {
  name        = "${var.project_name}-web-sg"
  description = "Allow HTTP only from ALB"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description     = "HTTP from ALB only"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id] # ALB SG에서 오는 트래픽만 허용
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.project_name}-web-sg" }
}

# --- 3) DB용 Security Group: WEB/WAS -> DB 3306 허용 ---
resource "aws_security_group" "db_sg" {
  name        = "${var.project_name}-db-sg"
  description = "Allow MySQL/MariaDB(3306) only from WEB/WAS tier"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description     = "MariaDB from WEB/WAS SG only"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.web_sg.id]
  }

  # DB끼리 복제(replication)를 위해 자기 자신 SG 트래픽도 허용
  ingress {
    description = "Replication traffic between DB nodes"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    self        = true
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.project_name}-db-sg" }
}

# ====================================================================
# 모듈 호출 순서 = 우리가 설계한 실행 순서 (DB -> EC2 -> ELB)
# ====================================================================

# --- 1단계: DB Cluster (MariaDB x2) ---
module "db_cluster" {
  source = "./modules/db"

  project_name       = var.project_name
  db_ami_id          = data.aws_ami.amazon_linux_2023.id
  db_instance_type   = var.db_instance_type
  private_subnet_ids = module.vpc.private_subnet_ids # <- vpc 모듈 output 사용
  key_name           = var.key_name
  db_sg_id           = aws_security_group.db_sg.id
  db_root_password   = var.db_root_password
  db_app_username    = var.db_app_username
  db_app_password    = var.db_app_password
  db_app_name        = var.db_app_name
}

# --- 2단계: EC2(WEB/WAS) + ASG ---
# db_cluster 모듈의 output을 실제로 사용하므로,
# db_cluster가 실패하면 이 모듈은 실행되지 않는다.
module "ec2_web" {
  source = "./modules/ec2"

  project_name      = var.project_name
  web_ami_id        = data.aws_ami.amazon_linux_2023.id
  web_instance_type = var.web_instance_type
  # EC2(WEB/WAS)는 Private Subnet에 배치 (외부에서 직접 접근 불가,
  # ALB를 통해서만 접근 가능하도록 하는 일반적인 3-tier 보안 구조)
  private_subnet_ids = module.vpc.private_subnet_ids
  key_name           = var.key_name
  web_sg_id          = aws_security_group.web_sg.id

  # <-- 핵심: DB 모듈의 output을 EC2 user_data에서 실제로 사용 -->
  db_master_endpoint = module.db_cluster.db_master_private_ip
  db_app_username    = var.db_app_username
  db_app_password    = var.db_app_password
  db_app_name        = var.db_app_name

  asg_min     = var.asg_min
  asg_max     = var.asg_max
  asg_desired = var.asg_desired
}

# --- 3단계: ELB(ALB) ---
# ec2_web 모듈의 output(asg_id)을 실제로 사용하므로,
# ec2_web(=db_cluster 포함)이 실패하면 이 모듈도 실행되지 않는다.
module "elb" {
  source = "./modules/elb"

  project_name      = var.project_name
  vpc_id            = module.vpc.vpc_id
  public_subnet_ids = module.vpc.public_subnet_ids
  alb_sg_id         = aws_security_group.alb_sg.id

  # <-- 핵심: EC2 모듈의 output을 ELB에서 실제로 사용 -->
  asg_id = module.ec2_web.asg_id
}
